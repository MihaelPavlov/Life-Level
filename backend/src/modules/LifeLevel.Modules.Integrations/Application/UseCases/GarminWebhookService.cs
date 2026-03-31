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

public class GarminWebhookService(
    DbContext db,
    HttpClient http,
    GarminOAuthService oAuth,
    HealthSyncService healthSync,
    IOptions<GarminOptions> opts)
{
    private readonly GarminOptions _opts = opts.Value;

    public bool VerifyChallenge(string verifyToken) =>
        verifyToken == _opts.WebhookVerifyToken;

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

    public async Task ProcessEventAsync(GarminWebhookEvent evt, CancellationToken ct = default)
    {
        if (evt.EventType != "activity" || evt.Action != "create") return;

        var conn = await db.Set<GarminConnection>()
            .FirstOrDefaultAsync(g => g.GarminUserId == evt.UserId && g.IsActive, ct);
        if (conn is null) return;

        await oAuth.RefreshTokenIfNeededAsync(conn, ct);

        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            $"https://connect.garmin.com/activity-service/activity/{evt.ActivityId}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", conn.AccessToken);

        var response = await http.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode) return;

        var activity = await response.Content.ReadFromJsonAsync<GarminActivityDto>(cancellationToken: ct);
        if (activity is null) return;

        var dto = new ExternalActivityDto
        {
            Provider     = IntegrationProviders.Garmin,
            ExternalId   = $"garmin:{evt.ActivityId}",
            ActivityType = ActivityTypeMapper.FromGarmin(activity.ActivityType),
            DurationMinutes = (int)Math.Round(activity.Duration / 60.0),
            DistanceKm   = activity.Distance > 0 ? activity.Distance / 1000.0 : null,
            Calories     = activity.Calories > 0 ? (int?)activity.Calories : null,
            PerformedAt  = activity.StartTimeLocal.ToUniversalTime(),
        };

        await healthSync.ImportSingleAsync(conn.UserId, dto, ct);
    }
}

// ── Webhook event payload ──────────────────────────────────────────────────────
public record GarminWebhookEvent(
    [property: JsonPropertyName("event_type")] string EventType,
    [property: JsonPropertyName("action")]     string Action,
    [property: JsonPropertyName("user_id")]    string UserId,
    [property: JsonPropertyName("activity_id")] long  ActivityId);

// ── Garmin activity API response ───────────────────────────────────────────────
internal record GarminActivityDto(
    [property: JsonPropertyName("activityType")]   string   ActivityType,
    [property: JsonPropertyName("duration")]       double   Duration,
    [property: JsonPropertyName("distance")]       double   Distance,
    [property: JsonPropertyName("calories")]       double   Calories,
    [property: JsonPropertyName("startTimeLocal")] DateTime StartTimeLocal);
