using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LifeLevel.Modules.Integrations.Application.UseCases;

public class GarminOAuthService(
    DbContext db,
    HttpClient http,
    IOptions<GarminOptions> opts)
{
    private readonly GarminOptions _opts = opts.Value;

    private const string TokenUrl = "https://connect.garmin.com/oauth2Token";

    public async Task<GarminStatusDto> GetStatusAsync(Guid userId, CancellationToken ct = default)
    {
        var conn = await db.Set<GarminConnection>()
            .FirstOrDefaultAsync(g => g.UserId == userId && g.IsActive, ct);
        if (conn is null) return new GarminStatusDto(false, null, null, null);
        return new GarminStatusDto(true, conn.DisplayName, conn.GarminUserId, conn.ConnectedAt);
    }

    public async Task<GarminStatusDto> ConnectAsync(Guid userId, GarminConnectRequest req, CancellationToken ct = default)
    {
        // Exchange authorization code + PKCE verifier for tokens
        var formData = new Dictionary<string, string>
        {
            ["grant_type"]    = "authorization_code",
            ["code"]          = req.Code,
            ["redirect_uri"]  = req.RedirectUri,
            ["code_verifier"] = req.CodeVerifier,
            ["client_id"]     = _opts.ClientId,
            ["client_secret"] = _opts.ClientSecret,
        };

        var tokenResp = await http.PostAsync(TokenUrl, new FormUrlEncodedContent(formData), ct);
        tokenResp.EnsureSuccessStatusCode();
        var token = await tokenResp.Content.ReadFromJsonAsync<GarminTokenResponseDto>(cancellationToken: ct)
                    ?? throw new InvalidOperationException("Empty token response from Garmin.");

        // Fetch profile to get user ID and display name
        using var profileReq = new HttpRequestMessage(HttpMethod.Get, "https://connect.garmin.com/userprofile-service/userprofile");
        profileReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.AccessToken);
        var profileResp = await http.SendAsync(profileReq, ct);
        profileResp.EnsureSuccessStatusCode();
        var profile = await profileResp.Content.ReadFromJsonAsync<GarminProfileDto>(cancellationToken: ct)
                      ?? throw new InvalidOperationException("Empty profile response from Garmin.");

        var conn = await db.Set<GarminConnection>()
            .FirstOrDefaultAsync(g => g.UserId == userId, ct);

        if (conn is null)
        {
            conn = new GarminConnection { Id = Guid.NewGuid(), UserId = userId, ConnectedAt = DateTime.UtcNow };
            db.Set<GarminConnection>().Add(conn);
        }

        conn.GarminUserId = profile.UserId;
        conn.DisplayName  = profile.DisplayName ?? profile.UserId;
        conn.AccessToken  = token.AccessToken;
        conn.RefreshToken = token.RefreshToken ?? string.Empty;
        conn.ExpiresAt    = DateTime.UtcNow.AddSeconds(token.ExpiresIn);
        conn.IsActive     = true;

        await db.SaveChangesAsync(ct);
        return new GarminStatusDto(true, conn.DisplayName, conn.GarminUserId, conn.ConnectedAt);
    }

    public async Task DisconnectAsync(Guid userId, CancellationToken ct = default)
    {
        var conn = await db.Set<GarminConnection>()
            .FirstOrDefaultAsync(g => g.UserId == userId && g.IsActive, ct);
        if (conn is null) return;

        conn.IsActive     = false;
        conn.AccessToken  = string.Empty;
        conn.RefreshToken = string.Empty;
        await db.SaveChangesAsync(ct);
    }

    public async Task RefreshTokenIfNeededAsync(GarminConnection conn, CancellationToken ct = default)
    {
        if (conn.ExpiresAt > DateTime.UtcNow.AddMinutes(5)) return;
        if (string.IsNullOrEmpty(conn.RefreshToken)) return;

        var formData = new Dictionary<string, string>
        {
            ["grant_type"]    = "refresh_token",
            ["refresh_token"] = conn.RefreshToken,
            ["client_id"]     = _opts.ClientId,
            ["client_secret"] = _opts.ClientSecret,
        };

        var resp = await http.PostAsync(TokenUrl, new FormUrlEncodedContent(formData), ct);
        if (!resp.IsSuccessStatusCode) return;

        var token = await resp.Content.ReadFromJsonAsync<GarminTokenResponseDto>(cancellationToken: ct);
        if (token is null) return;

        conn.AccessToken  = token.AccessToken;
        conn.RefreshToken = token.RefreshToken ?? conn.RefreshToken;
        conn.ExpiresAt    = DateTime.UtcNow.AddSeconds(token.ExpiresIn);
        await db.SaveChangesAsync(ct);
    }
}

// ── Internal DTOs ──────────────────────────────────────────────────────────────
internal record GarminTokenResponseDto(
    [property: JsonPropertyName("access_token")]  string  AccessToken,
    [property: JsonPropertyName("refresh_token")] string? RefreshToken,
    [property: JsonPropertyName("expires_in")]    int     ExpiresIn);

internal record GarminProfileDto(
    [property: JsonPropertyName("userId")]       string  UserId,
    [property: JsonPropertyName("displayName")]  string? DisplayName);
