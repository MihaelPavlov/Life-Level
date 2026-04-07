using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Integrations.Application;
using LifeLevel.Modules.Integrations.Application.UseCases;
using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LifeLevel.Api.Tests;

public class StravaOAuthServiceTests
{
    private static readonly StravaOptions TestOptions = new()
    {
        ClientId = "12345",
        ClientSecret = "test-secret",
        WebhookVerifyToken = "test-token"
    };

    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private static StravaOAuthService CreateService(AppDbContext db, HttpClient? http = null)
    {
        return new StravaOAuthService(db, http ?? new HttpClient(), Options.Create(TestOptions));
    }

    // ── GetStatusAsync ───────────────────────────────────────────────────────

    [Fact]
    public async Task GetStatusAsync_NoConnection_ReturnsDisconnected()
    {
        var db = CreateDb(nameof(GetStatusAsync_NoConnection_ReturnsDisconnected));
        var service = CreateService(db);

        var status = await service.GetStatusAsync(Guid.NewGuid());

        Assert.False(status.IsConnected);
        Assert.Null(status.AthleteName);
        Assert.Null(status.AthleteId);
        Assert.Null(status.ConnectedAt);
    }

    [Fact]
    public async Task GetStatusAsync_ActiveConnection_ReturnsConnected()
    {
        var db = CreateDb(nameof(GetStatusAsync_ActiveConnection_ReturnsConnected));
        var userId = Guid.NewGuid();
        db.Users.Add(new User { Id = userId, Username = "strava-user", Email = "s@test.com", PasswordHash = "x" });

        var connectedAt = DateTime.UtcNow.AddDays(-7);
        db.StravaConnections.Add(new StravaConnection
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            StravaAthleteId = 12345,
            AthleteName = "John Doe",
            AccessToken = "token",
            RefreshToken = "refresh",
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            IsActive = true,
            ConnectedAt = connectedAt
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var status = await service.GetStatusAsync(userId);

        Assert.True(status.IsConnected);
        Assert.Equal("John Doe", status.AthleteName);
        Assert.Equal(12345, status.AthleteId);
        Assert.Equal(connectedAt, status.ConnectedAt);
    }

    [Fact]
    public async Task GetStatusAsync_InactiveConnection_ReturnsDisconnected()
    {
        var db = CreateDb(nameof(GetStatusAsync_InactiveConnection_ReturnsDisconnected));
        var userId = Guid.NewGuid();
        db.Users.Add(new User { Id = userId, Username = "strava-inactive", Email = "si@test.com", PasswordHash = "x" });

        db.StravaConnections.Add(new StravaConnection
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            StravaAthleteId = 999,
            AthleteName = "Disconnected User",
            AccessToken = "",
            RefreshToken = "",
            ExpiresAt = DateTime.UtcNow,
            IsActive = false,
            ConnectedAt = DateTime.UtcNow.AddDays(-30)
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var status = await service.GetStatusAsync(userId);

        Assert.False(status.IsConnected);
    }

    // ── DisconnectAsync ──────────────────────────────────────────────────────

    [Fact]
    public async Task DisconnectAsync_ActiveConnection_DeactivatesAndClearsTokens()
    {
        var db = CreateDb(nameof(DisconnectAsync_ActiveConnection_DeactivatesAndClearsTokens));
        var userId = Guid.NewGuid();
        db.Users.Add(new User { Id = userId, Username = "strava-disc", Email = "sd@test.com", PasswordHash = "x" });

        db.StravaConnections.Add(new StravaConnection
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            StravaAthleteId = 111,
            AthleteName = "To Disconnect",
            AccessToken = "old-token",
            RefreshToken = "old-refresh",
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            IsActive = true,
            ConnectedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();

        // Use a handler that always returns OK so the deauth HTTP call doesn't fail
        var handler = new FakeHttpHandler(System.Net.HttpStatusCode.OK);
        var httpClient = new HttpClient(handler);
        var service = CreateService(db, httpClient);

        await service.DisconnectAsync(userId);

        var conn = await db.StravaConnections.FirstAsync(c => c.UserId == userId);
        Assert.False(conn.IsActive);
        Assert.Equal(string.Empty, conn.AccessToken);
        Assert.Equal(string.Empty, conn.RefreshToken);
    }

    [Fact]
    public async Task DisconnectAsync_NoConnection_DoesNothing()
    {
        var db = CreateDb(nameof(DisconnectAsync_NoConnection_DoesNothing));
        var service = CreateService(db);

        // Should not throw
        await service.DisconnectAsync(Guid.NewGuid());
    }

    [Fact]
    public async Task DisconnectAsync_HttpFailure_StillDeactivatesLocally()
    {
        var db = CreateDb(nameof(DisconnectAsync_HttpFailure_StillDeactivatesLocally));
        var userId = Guid.NewGuid();
        db.Users.Add(new User { Id = userId, Username = "strava-fail", Email = "sf@test.com", PasswordHash = "x" });

        db.StravaConnections.Add(new StravaConnection
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            StravaAthleteId = 222,
            AthleteName = "Fail User",
            AccessToken = "token",
            RefreshToken = "refresh",
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            IsActive = true,
            ConnectedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();

        // HTTP handler that throws to simulate network failure
        var handler = new FakeHttpHandler(throwException: true);
        var httpClient = new HttpClient(handler);
        var service = CreateService(db, httpClient);

        await service.DisconnectAsync(userId);

        var conn = await db.StravaConnections.FirstAsync(c => c.UserId == userId);
        Assert.False(conn.IsActive);
        Assert.Equal(string.Empty, conn.AccessToken);
    }

    // ── RefreshTokenIfNeededAsync ────────────────────────────────────────────

    [Fact]
    public async Task RefreshTokenIfNeeded_TokenNotExpired_DoesNotCallApi()
    {
        var db = CreateDb(nameof(RefreshTokenIfNeeded_TokenNotExpired_DoesNotCallApi));

        var handler = new FakeHttpHandler(throwException: true); // would throw if called
        var httpClient = new HttpClient(handler);
        var service = CreateService(db, httpClient);

        var conn = new StravaConnection
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            StravaAthleteId = 333,
            AccessToken = "still-valid",
            RefreshToken = "refresh",
            ExpiresAt = DateTime.UtcNow.AddHours(2), // well in the future
            IsActive = true,
            ConnectedAt = DateTime.UtcNow
        };

        // Should NOT call the HTTP client (which would throw)
        await service.RefreshTokenIfNeededAsync(conn);

        Assert.Equal("still-valid", conn.AccessToken); // unchanged
    }
}
