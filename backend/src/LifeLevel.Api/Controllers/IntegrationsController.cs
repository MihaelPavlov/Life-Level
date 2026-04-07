using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/integrations")]
[Authorize]
public class IntegrationsController(
    HealthSyncService healthSync,
    StravaOAuthService stravaOAuth,
    StravaWebhookService stravaWebhook,
    GarminOAuthService garminOAuth,
    GarminWebhookService garminWebhook,
    IUserContext userContext) : ControllerBase
{
    [HttpPost("health/sync")]
    public async Task<IActionResult> SyncHealth(
        [FromBody] SyncBatchRequest request,
        CancellationToken ct)
    {
        if (request.Activities is null || request.Activities.Count == 0)
            return Ok(new SyncResult());

        var userId = userContext.UserId;
        var result = await healthSync.SyncBatchAsync(userId, request, ct);
        return Ok(result);
    }

    /// <summary>
    /// POST /api/integrations/health/reprocess-stuck
    /// Repairs ExternalActivityRecords that were written (WasImported=false) but never finished
    /// processing into the game. Torn-write records (Activity already saved) get their flag
    /// repaired in-place. Fully missing records are reported so the client can re-sync from
    /// the provider.
    /// </summary>
    [HttpPost("health/reprocess-stuck")]
    public async Task<IActionResult> ReprocessStuck(CancellationToken ct)
    {
        var result = await healthSync.ReprocessStuckAsync(userContext.UserId, ct);
        return Ok(result);
    }

    [HttpGet("strava/status")]
    public async Task<IActionResult> StravaStatus(CancellationToken ct)
    {
        var userId = userContext.UserId;
        var status = await stravaOAuth.GetStatusAsync(userId, ct);
        return Ok(status);
    }

    [HttpPost("strava/connect")]
    public async Task<IActionResult> StravaConnect([FromBody] StravaConnectRequest req, CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            var status = await stravaOAuth.ConnectAsync(userId, req, ct);
            return Ok(status);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ex.Message);
        }
        catch (HttpRequestException ex)
        {
            return BadRequest($"Strava token exchange failed: {ex.Message}");
        }
        catch (DbUpdateException)
        {
            // Concurrent insert race — connection already saved by a parallel request
            var status = await stravaOAuth.GetStatusAsync(userId, ct);
            return Ok(status);
        }
    }

    [HttpDelete("strava/disconnect")]
    public async Task<IActionResult> StravaDisconnect(CancellationToken ct)
    {
        var userId = userContext.UserId;
        await stravaOAuth.DisconnectAsync(userId, ct);
        return NoContent();
    }

    /// <summary>POST /api/integrations/strava/sync — manual pull of recent activities</summary>
    [HttpPost("strava/sync")]
    public async Task<IActionResult> StravaSyncManual(CancellationToken ct)
    {
        var result = await stravaWebhook.SyncRecentAsync(userContext.UserId, ct);
        return Ok(result);
    }

    /// <summary>POST /api/integrations/sync-all — sync all connected server-side integrations</summary>
    [HttpPost("sync-all")]
    public async Task<IActionResult> SyncAll(CancellationToken ct)
    {
        var userId = userContext.UserId;
        var totalImported = 0;
        var totalSkipped = 0;
        var errors = new List<string>();

        // Strava
        try
        {
            var stravaStatus = await stravaOAuth.GetStatusAsync(userId, ct);
            if (stravaStatus.IsConnected)
            {
                var result = await stravaWebhook.SyncRecentAsync(userId, ct);
                totalImported += result.Imported;
                totalSkipped += result.Skipped;
                errors.AddRange(result.Errors);
            }
        }
        catch (Exception ex) { errors.Add($"Strava: {ex.Message}"); }

        // Garmin — add here when SyncRecentAsync is implemented

        return Ok(new SyncResult
        {
            Imported = totalImported,
            Skipped = totalSkipped,
            Errors = errors,
        });
    }

    // ── Strava Webhook ────────────────────────────────────────────────────────

    /// <summary>GET /api/integrations/strava/webhook — hub.challenge handshake</summary>
    [HttpGet("strava/webhook")]
    [AllowAnonymous]
    public IActionResult StravaWebhookChallenge(
        [FromQuery(Name = "hub.verify_token")] string verifyToken,
        [FromQuery(Name = "hub.challenge")]    string challenge,
        [FromQuery(Name = "hub.mode")]         string mode)
    {
        if (mode != "subscribe") return BadRequest("Invalid hub.mode.");
        if (!stravaWebhook.VerifyChallenge(verifyToken)) return Unauthorized("Invalid verify token.");
        return Ok(new Dictionary<string, string> { ["hub.challenge"] = challenge });
    }

    /// <summary>POST /api/integrations/strava/webhook — incoming activity events</summary>
    [HttpPost("strava/webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> StravaWebhookEvent(
        [FromBody] StravaWebhookEvent evt,
        CancellationToken ct)
    {
        await stravaWebhook.ProcessEventAsync(evt, ct);
        return Ok();
    }

    // ── Garmin ────────────────────────────────────────────────────────────────

    [HttpGet("garmin/status")]
    public async Task<IActionResult> GarminStatus(CancellationToken ct)
    {
        var status = await garminOAuth.GetStatusAsync(userContext.UserId, ct);
        return Ok(status);
    }

    [HttpPost("garmin/connect")]
    public async Task<IActionResult> GarminConnect([FromBody] GarminConnectRequest req, CancellationToken ct)
    {
        try
        {
            var status = await garminOAuth.ConnectAsync(userContext.UserId, req, ct);
            return Ok(status);
        }
        catch (HttpRequestException ex)
        {
            return BadRequest($"Garmin token exchange failed: {ex.Message}");
        }
    }

    [HttpDelete("garmin/disconnect")]
    public async Task<IActionResult> GarminDisconnect(CancellationToken ct)
    {
        await garminOAuth.DisconnectAsync(userContext.UserId, ct);
        return NoContent();
    }

    /// <summary>GET /api/integrations/garmin/webhook — challenge handshake</summary>
    [HttpGet("garmin/webhook")]
    [AllowAnonymous]
    public IActionResult GarminWebhookChallenge(
        [FromQuery(Name = "verify_token")] string verifyToken,
        [FromQuery(Name = "challenge")]    string challenge)
    {
        if (!garminWebhook.VerifyChallenge(verifyToken)) return Unauthorized("Invalid verify token.");
        return Ok(new { challenge });
    }

    /// <summary>POST /api/integrations/garmin/webhook — incoming activity events</summary>
    [HttpPost("garmin/webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> GarminWebhookEvent(
        [FromBody] GarminWebhookEvent evt,
        CancellationToken ct)
    {
        await garminWebhook.ProcessEventAsync(evt, ct);
        return Ok();
    }
}
