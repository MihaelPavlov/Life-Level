using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Serialization;
using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Application.Mappers;
using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LifeLevel.Modules.Integrations.Application.UseCases;

public class StravaWebhookService(
    DbContext db,
    HttpClient http,
    StravaOAuthService oAuth,
    HealthSyncService healthSync,
    IOptions<StravaOptions> opts)
{
    private readonly StravaOptions _opts = opts.Value;

    /// <summary>Verifies Strava hub.verify_token for GET /strava/webhook</summary>
    public bool VerifyChallenge(string verifyToken) =>
        verifyToken == _opts.WebhookVerifyToken;

    /// <summary>
    /// Verifies the X-Hub-Signature header on the raw body.
    /// Strava sends: sha256=&lt;hex&gt;
    /// </summary>
    public bool VerifySignature(string signatureHeader, byte[] rawBody)
    {
        if (!signatureHeader.StartsWith("sha256=")) return false;
        var expectedHex = signatureHeader["sha256=".Length..];

        var keyBytes = Encoding.UTF8.GetBytes(_opts.ClientSecret);
        var hash = HMACSHA256.HashData(keyBytes, rawBody);
        var actualHex = Convert.ToHexString(hash).ToLowerInvariant();

        return CryptographicOperations.FixedTimeEquals(
            Encoding.ASCII.GetBytes(actualHex),
            Encoding.ASCII.GetBytes(expectedHex));
    }

    /// <summary>Processes an inbound Strava webhook event payload.</summary>
    public async Task ProcessEventAsync(StravaWebhookEvent evt, CancellationToken ct = default)
    {
        // Only handle activity creation events
        if (evt.ObjectType != "activity" || evt.AspectType != "create") return;

        var conn = await db.Set<StravaConnection>()
            .FirstOrDefaultAsync(s => s.StravaAthleteId == evt.OwnerId && s.IsActive, ct);
        if (conn is null) return;

        await oAuth.RefreshTokenIfNeededAsync(conn, ct);

        // Fetch full activity from Strava API
        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            $"https://www.strava.com/api/v3/activities/{evt.ObjectId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", conn.AccessToken);

        var response = await http.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode) return;

        var activity = await response.Content.ReadFromJsonAsync<StravaActivityDto>(cancellationToken: ct);
        if (activity is null) return;

        var dto = new ExternalActivityDto
        {
            Provider = IntegrationProviders.Strava,
            ExternalId = $"strava:{evt.ObjectId}",
            ActivityType = ActivityTypeMapper.FromStrava(activity.SportType),
            DurationMinutes = (int)Math.Round(activity.MovingTime / 60.0),
            DistanceKm = activity.Distance > 0 ? activity.Distance / 1000.0 : null,
            Calories = activity.Calories > 0 ? (int?)activity.Calories : null,
            PerformedAt = activity.StartDateLocal.ToUniversalTime(),
        };

        await healthSync.ImportSingleAsync(conn.UserId, dto, ct);
    }

    /// <summary>
    /// Fetches recent activities from Strava API (last 30 days) and imports them.
    /// Called by POST /api/integrations/strava/sync for manual pull.
    /// </summary>
    public async Task<SyncResult> SyncRecentAsync(Guid userId, CancellationToken ct = default)
    {
        var conn = await db.Set<StravaConnection>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.IsActive, ct);
        if (conn is null)
            return new SyncResult { Errors = ["No active Strava connection found."] };

        await oAuth.RefreshTokenIfNeededAsync(conn, ct);

        var after = (long)DateTimeOffset.UtcNow.AddDays(-30).ToUnixTimeSeconds();
        var url = $"https://www.strava.com/api/v3/athlete/activities?after={after}&per_page=50";

        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", conn.AccessToken);

        var response = await http.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode)
            return new SyncResult { Errors = [$"Strava API error: {response.StatusCode}"] };

        var activities = await response.Content.ReadFromJsonAsync<List<StravaActivityDto>>(cancellationToken: ct);
        if (activities is null || activities.Count == 0)
            return new SyncResult();

        int imported = 0, skipped = 0;
        var errors = new List<string>();

        foreach (var activity in activities)
        {
            var dto = new ExternalActivityDto
            {
                Provider = IntegrationProviders.Strava,
                ExternalId = $"strava:{activity.Id}",
                ActivityType = ActivityTypeMapper.FromStrava(activity.SportType),
                DurationMinutes = (int)Math.Round(activity.MovingTime / 60.0),
                DistanceKm = activity.Distance > 0 ? activity.Distance / 1000.0 : null,
                Calories = activity.Calories > 0 ? (int?)activity.Calories : null,
                PerformedAt = activity.StartDateLocal.ToUniversalTime(),
            };

            var result = await healthSync.ImportSingleAsync(conn.UserId, dto, ct);
            imported += result.Imported;
            skipped += result.Skipped;
            errors.AddRange(result.Errors);
        }

        return new SyncResult { Imported = imported, Skipped = skipped, Errors = errors };
    }

}

// ── Webhook event payload (public so the controller can use it as [FromBody]) ──
public record StravaWebhookEvent(
    [property: JsonPropertyName("object_type")] string ObjectType,
    [property: JsonPropertyName("object_id")]   long   ObjectId,
    [property: JsonPropertyName("aspect_type")] string AspectType,
    [property: JsonPropertyName("owner_id")]    long   OwnerId);

// ── Strava activity API response (only fields we need) ────────────────────────
internal record StravaActivityDto(
    [property: JsonPropertyName("id")]               long     Id,
    [property: JsonPropertyName("sport_type")]       string   SportType,
    [property: JsonPropertyName("moving_time")]      int      MovingTime,
    [property: JsonPropertyName("distance")]         double   Distance,
    [property: JsonPropertyName("calories")]         double   Calories,
    [property: JsonPropertyName("start_date_local")] DateTime StartDateLocal);
