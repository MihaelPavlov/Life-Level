using System.Net.Http.Json;
using System.Text.Json.Serialization;
using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LifeLevel.Modules.Integrations.Application.UseCases;

public class StravaOAuthService(
    DbContext db,
    HttpClient http,
    IOptions<StravaOptions> opts)
{
    private readonly StravaOptions _opts = opts.Value;

    public async Task<StravaStatusDto> GetStatusAsync(Guid userId, CancellationToken ct = default)
    {
        var conn = await db.Set<StravaConnection>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.IsActive, ct);

        if (conn is null)
            return new StravaStatusDto(false, null, null, null);

        return new StravaStatusDto(true, conn.AthleteName, conn.StravaAthleteId, conn.ConnectedAt);
    }

    public async Task<StravaStatusDto> ConnectAsync(Guid userId, StravaConnectRequest req, CancellationToken ct = default)
    {
        var form = new Dictionary<string, string>
        {
            ["client_id"]     = _opts.ClientId,
            ["client_secret"] = _opts.ClientSecret,
            ["code"]          = req.Code,
            ["grant_type"]    = "authorization_code",
        };

        var response = await http.PostAsync(
            "https://www.strava.com/oauth/token",
            new FormUrlEncodedContent(form), ct);
        response.EnsureSuccessStatusCode();

        var token = await response.Content.ReadFromJsonAsync<StravaTokenResponseDto>(cancellationToken: ct)
            ?? throw new InvalidOperationException("Empty token response from Strava");

        var existing = await db.Set<StravaConnection>()
            .FirstOrDefaultAsync(s => s.UserId == userId, ct);

        if (existing is null)
        {
            existing = new StravaConnection
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ConnectedAt = DateTime.UtcNow,
            };
            db.Set<StravaConnection>().Add(existing);
        }

        existing.StravaAthleteId = token.Athlete.Id;
        existing.AthleteName = $"{token.Athlete.Firstname} {token.Athlete.Lastname}".Trim();
        existing.AccessToken = token.AccessToken;
        existing.RefreshToken = token.RefreshToken;
        existing.ExpiresAt = DateTimeOffset.FromUnixTimeSeconds(token.ExpiresAt).UtcDateTime;
        existing.IsActive = true;

        await db.SaveChangesAsync(ct);
        return new StravaStatusDto(true, existing.AthleteName, existing.StravaAthleteId, existing.ConnectedAt);
    }

    public async Task DisconnectAsync(Guid userId, CancellationToken ct = default)
    {
        var conn = await db.Set<StravaConnection>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.IsActive, ct);

        if (conn is null) return;

        try
        {
            await RefreshTokenIfNeededAsync(conn, ct);
            using var deauthReq = new HttpRequestMessage(HttpMethod.Post, "https://www.strava.com/oauth/deauthorize");
            deauthReq.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", conn.AccessToken);
            await http.SendAsync(deauthReq, ct);
        }
        catch { /* ignore — disconnect locally regardless */ }

        conn.IsActive = false;
        conn.AccessToken = string.Empty;
        conn.RefreshToken = string.Empty;
        await db.SaveChangesAsync(ct);
    }

    public async Task RefreshTokenIfNeededAsync(StravaConnection conn, CancellationToken ct = default)
    {
        if (conn.ExpiresAt > DateTime.UtcNow.AddMinutes(5)) return;

        var form = new Dictionary<string, string>
        {
            ["client_id"]     = _opts.ClientId,
            ["client_secret"] = _opts.ClientSecret,
            ["grant_type"]    = "refresh_token",
            ["refresh_token"] = conn.RefreshToken,
        };

        var response = await http.PostAsync(
            "https://www.strava.com/oauth/token",
            new FormUrlEncodedContent(form), ct);
        response.EnsureSuccessStatusCode();

        var token = await response.Content.ReadFromJsonAsync<StravaRefreshResponseDto>(cancellationToken: ct)
            ?? throw new InvalidOperationException("Empty refresh response from Strava");

        conn.AccessToken = token.AccessToken;
        conn.RefreshToken = token.RefreshToken;
        conn.ExpiresAt = DateTimeOffset.FromUnixTimeSeconds(token.ExpiresAt).UtcDateTime;
        await db.SaveChangesAsync(ct);
    }
}

// Internal JSON DTOs — Strava snake_case API responses
internal record StravaTokenResponseDto(
    [property: JsonPropertyName("access_token")]  string AccessToken,
    [property: JsonPropertyName("refresh_token")] string RefreshToken,
    [property: JsonPropertyName("expires_at")]    long ExpiresAt,
    [property: JsonPropertyName("athlete")]       StravaAthleteDto Athlete);

internal record StravaAthleteDto(
    [property: JsonPropertyName("id")]        long Id,
    [property: JsonPropertyName("firstname")] string Firstname,
    [property: JsonPropertyName("lastname")]  string Lastname);

internal record StravaRefreshResponseDto(
    [property: JsonPropertyName("access_token")]  string AccessToken,
    [property: JsonPropertyName("refresh_token")] string RefreshToken,
    [property: JsonPropertyName("expires_at")]    long ExpiresAt);
