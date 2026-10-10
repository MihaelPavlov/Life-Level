using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Application.Mappers;
using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using LifeLevel.SharedKernel.Abstractions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LifeLevel.Modules.Integrations.Application.UseCases;

public class StravaWebhookService(
    DbContext db,
    HttpClient http,
    StravaOAuthService oAuth,
    HealthSyncService healthSync,
    PendingActivityService pending,
    IOptions<StravaOptions> opts,
    ILogger<StravaWebhookService> logger)
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
            DurationMinutes = DurationMinutes(activity),
            DistanceKm = activity.Distance > 0 ? activity.Distance / 1000.0 : null,
            Calories = activity.Calories > 0 ? (int?)activity.Calories : null,
            RecordingMethod = activity.Manual ? ActivityRecordingMethod.Manual : ActivityRecordingMethod.Automatic,
            PerformedAt = activity.StartDateLocal.ToUniversalTime(),
        };

        // Queue it for the player to import from Home instead of awarding XP now.
        // The payload is stored in full, so importing never calls the provider again.
        if (await pending.EnqueueAsync(conn.UserId, dto, ct))
            await pending.NotifyIfFirstPendingAsync(conn.UserId, ct);
    }

    /// <summary>
    /// Fetches recent activities from Strava API (last 30 days) and imports them.
    /// Called by POST /api/integrations/strava/sync for manual pull.
    /// </summary>
    public async Task<SyncResult> SyncRecentAsync(Guid userId, CancellationToken ct = default)
    {
        var (activities, error) = await FetchRecentAsync(userId, days: 30, ct);
        if (error != null) return new SyncResult { Errors = [error] };

        int imported = 0, skipped = 0, rejectedManual = 0;
        double totalAdventureDistanceKm = 0;
        var errors = new List<string>();
        foreach (var dto in activities)
        {
            if (dto.RecordingMethod == ActivityRecordingMethod.Manual)
            {
                await pending.EnqueueAsync(userId, dto, ct);
                rejectedManual++;
                continue;
            }
            var result = await healthSync.ImportSingleAsync(userId, dto, ct);
            imported += result.Imported;
            skipped += result.Skipped;
            totalAdventureDistanceKm += result.TotalAdventureDistanceKm;
            errors.AddRange(result.Errors);
        }

        return new SyncResult
        {
            Imported = imported,
            Skipped = skipped,
            RejectedManual = rejectedManual,
            TotalAdventureDistanceKm = totalAdventureDistanceKm,
            Errors = errors,
        };
    }

    /// <summary>
    /// Explicit player sync: fetch recent Strava activities into the review
    /// queue. Webhooks only cover new events, so this also finds workouts
    /// recorded before the athlete connected Life-Level.
    /// </summary>
    public async Task<PendingActivityListDto> StageRecentAsync(Guid userId, CancellationToken ct = default)
    {
        var status = await oAuth.GetStatusAsync(userId, ct);
        if (!status.IsConnected)
            return await pending.ListAsync(userId, ct);

        var (activities, error) = await FetchRecentAsync(userId, days: 30, ct);
        if (error is not null)
            throw new DomainException("strava_sync_failed",
                "Could not sync Strava right now. Try again shortly.",
                DomainErrorKind.UpstreamUnavailable);

        foreach (var activity in activities)
            await pending.EnqueueAsync(userId, activity, ct);

        return await pending.ListAsync(userId, ct);
    }

    /// <summary>
    /// Pulls the athlete's activities from the last <paramref name="days"/> days
    /// (up to 200) and maps them to <see cref="ExternalActivityDto"/>. Returns an
    /// error message instead of throwing when Strava can't be reached.
    /// </summary>
    public async Task<(List<ExternalActivityDto> Activities, string? Error)> FetchRecentAsync(
        Guid userId, int days, CancellationToken ct = default)
    {
        var conn = await db.Set<StravaConnection>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.IsActive, ct);
        if (conn is null)
            return ([], "No active Strava connection found.");

        await oAuth.RefreshTokenIfNeededAsync(conn, ct);

        var after = DateTimeOffset.UtcNow.AddDays(-days).ToUnixTimeSeconds();
        var url = $"https://www.strava.com/api/v3/athlete/activities?after={after}&per_page=200";

        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", conn.AccessToken);

        using var response = await http.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode)
        {
            // Strava's JSON message explains permission and app-capacity failures.
            // Never log the response body: it can contain data we did not expect.
            string? reason = null;
            try
            {
                using var payload = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
                if (payload.RootElement.TryGetProperty("message", out var message) &&
                    message.ValueKind == JsonValueKind.String)
                    reason = message.GetString();
                if (payload.RootElement.TryGetProperty("errors", out var errors) &&
                    errors.ValueKind == JsonValueKind.Array && errors.GetArrayLength() > 0)
                {
                    var first = errors[0];
                    if (first.ValueKind == JsonValueKind.Object &&
                        first.TryGetProperty("field", out var field) && field.ValueKind == JsonValueKind.String &&
                        first.TryGetProperty("code", out var code) && code.ValueKind == JsonValueKind.String)
                        reason = $"{reason}: {field.GetString()} {code.GetString()}";
                }
            }
            catch (JsonException) { /* Strava occasionally returns non-JSON errors. */ }

            reason = reason is { Length: > 160 } ? reason[..160] : reason;
            logger.LogWarning("Strava activity fetch failed for user {UserId}: HTTP {StatusCode}, message {StravaMessage}",
                userId, (int)response.StatusCode, reason ?? "unavailable");
            var detail = string.IsNullOrWhiteSpace(reason) ? "" : $" ({reason})";
            return ([], $"Strava API error: {(int)response.StatusCode}{detail}. Try reconnecting Strava if this continues.");
        }

        var activities = await response.Content.ReadFromJsonAsync<List<StravaActivityDto>>(cancellationToken: ct);
        if (activities is null || activities.Count == 0)
            return ([], null);

        return (activities.Select(activity => new ExternalActivityDto
        {
            Provider = IntegrationProviders.Strava,
            ExternalId = $"strava:{activity.Id}",
            ActivityType = ActivityTypeMapper.FromStrava(activity.SportType),
            DurationMinutes = DurationMinutes(activity),
            DistanceKm = activity.Distance > 0 ? activity.Distance / 1000.0 : null,
            Calories = activity.Calories > 0 ? (int?)activity.Calories : null,
            RecordingMethod = activity.Manual ? ActivityRecordingMethod.Manual : ActivityRecordingMethod.Automatic,
            PerformedAt = activity.StartDateLocal.ToUniversalTime(),
        }).ToList(), null);
    }

    private static int DurationMinutes(StravaActivityDto activity)
    {
        var seconds = activity.MovingTime > 0 ? activity.MovingTime : activity.ElapsedTime;
        return seconds <= 0 ? 0 : Math.Max(1, (int)Math.Round(seconds / 60.0));
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
    [property: JsonPropertyName("manual")]           bool     Manual,
    [property: JsonPropertyName("start_date_local")] DateTime StartDateLocal,
    [property: JsonPropertyName("elapsed_time")]     int      ElapsedTime = 0);
