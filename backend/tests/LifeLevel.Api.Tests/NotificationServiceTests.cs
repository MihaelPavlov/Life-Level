using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Notifications.Application.Ports.Out;
using LifeLevel.Modules.Notifications.Application.UseCases;
using LifeLevel.Modules.Notifications.Domain.Entities;
using LifeLevel.Modules.Notifications.Domain.Enums;
using LifeLevel.Modules.Notifications.Infrastructure.Persistence.Repositories;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class NotificationServiceTests
{
    private static AppDbContext CreateDb(string name)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(name)
            .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.InMemoryEventId.TransactionIgnoredWarning))
            .Options;
        return new AppDbContext(options);
    }

    private sealed class FixedClock(DateTime utcNow) : ICurrentClock
    {
        public DateTime UtcNow { get; set; } = utcNow;
    }

    private sealed class RecordingFcmSender : IFcmSender
    {
        public int SendCallCount { get; private set; }
        public Func<string, FcmSendResult>? ResultForToken { get; set; }

        public Task<FcmSendResult> SendAsync(
            string token, string title, string body,
            IDictionary<string, string>? data, CancellationToken ct = default)
        {
            SendCallCount++;
            var result = ResultForToken?.Invoke(token) ?? new FcmSendResult(true, false, null);
            return Task.FromResult(result);
        }
    }

    private static (NotificationService svc, RecordingFcmSender fcm, AppDbContext db) BuildService(
        string dbName, DateTime nowUtc)
    {
        var db = CreateDb(dbName);
        var fcm = new RecordingFcmSender();
        var clock = new FixedClock(nowUtc);
        var repo = new NotificationRepository(db);
        var svc = new NotificationService(repo, fcm, clock);
        return (svc, fcm, db);
    }

    private static async Task SeedTokenAsync(AppDbContext db, Guid userId, string token = "tok-1")
    {
        db.Set<DeviceToken>().Add(new DeviceToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Token = token,
            Platform = DevicePlatform.Android,
            RegisteredAt = DateTime.UtcNow,
            LastUsedAt = DateTime.UtcNow,
            IsActive = true
        });
        await db.SaveChangesAsync();
    }

    // ── NoActiveTokens ───────────────────────────────────────────────────────

    [Fact]
    public async Task SendToUser_NoActiveTokens_ReturnsNoActiveTokensAndLogs()
    {
        // 12:00 UTC — outside quiet hours so only the "no tokens" path matters.
        var (svc, fcm, db) = BuildService(nameof(SendToUser_NoActiveTokens_ReturnsNoActiveTokensAndLogs),
            new DateTime(2026, 4, 17, 12, 0, 0, DateTimeKind.Utc));

        var result = await svc.SendToUserAsync(Guid.NewGuid(), "test", "t", "b");

        Assert.False(result.Sent);
        Assert.Equal("NoActiveTokens", result.Reason);
        Assert.Equal(0, fcm.SendCallCount);
        var log = await db.Set<NotificationLog>().SingleAsync();
        Assert.Equal(NotificationOutcome.NoActiveTokens, log.Outcome);
    }

    // ── QuietHours ───────────────────────────────────────────────────────────

    [Fact]
    public async Task SendToUser_InQuietHours_NonCritical_IsSuppressed()
    {
        var userId = Guid.NewGuid();
        // 23:00 UTC falls inside the quiet-hours window.
        var (svc, fcm, db) = BuildService(nameof(SendToUser_InQuietHours_NonCritical_IsSuppressed),
            new DateTime(2026, 4, 17, 23, 0, 0, DateTimeKind.Utc));
        await SeedTokenAsync(db, userId);

        var result = await svc.SendToUserAsync(userId, "cat", "t", "b", isCritical: false);

        Assert.False(result.Sent);
        Assert.Equal("QuietHours", result.Reason);
        Assert.Equal(0, fcm.SendCallCount);
        var log = await db.Set<NotificationLog>().SingleAsync();
        Assert.Equal(NotificationOutcome.SkippedQuietHours, log.Outcome);
    }

    [Fact]
    public async Task SendToUser_InQuietHours_Critical_BypassesAndSends()
    {
        var userId = Guid.NewGuid();
        var (svc, fcm, db) = BuildService(nameof(SendToUser_InQuietHours_Critical_BypassesAndSends),
            new DateTime(2026, 4, 17, 3, 30, 0, DateTimeKind.Utc)); // deep quiet hours
        await SeedTokenAsync(db, userId);

        var result = await svc.SendToUserAsync(userId, "cat", "t", "b", isCritical: true);

        Assert.True(result.Sent);
        Assert.Equal("Sent", result.Reason);
        Assert.Equal(1, fcm.SendCallCount);
    }

    // ── DailyCap ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task SendToUser_WhenDailyCapHit_NonCritical_IsSuppressed()
    {
        var userId = Guid.NewGuid();
        var nowUtc = new DateTime(2026, 4, 17, 14, 0, 0, DateTimeKind.Utc);
        var (svc, fcm, db) = BuildService(nameof(SendToUser_WhenDailyCapHit_NonCritical_IsSuppressed), nowUtc);
        await SeedTokenAsync(db, userId);

        // Seed 3 prior successful non-critical sends today.
        var todayStart = new DateTime(nowUtc.Year, nowUtc.Month, nowUtc.Day, 0, 0, 0, DateTimeKind.Utc);
        for (var i = 0; i < 3; i++)
        {
            db.Set<NotificationLog>().Add(new NotificationLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Category = "seed",
                Title = "t",
                Body = "b",
                IsCritical = false,
                SentAt = todayStart.AddHours(i + 1),
                Outcome = NotificationOutcome.Sent
            });
        }
        await db.SaveChangesAsync();

        var result = await svc.SendToUserAsync(userId, "cat", "t", "b", isCritical: false);

        Assert.False(result.Sent);
        Assert.Equal("DailyCap", result.Reason);
        Assert.Equal(0, fcm.SendCallCount);
    }

    [Fact]
    public async Task SendToUser_WhenDailyCapHit_Critical_StillSends()
    {
        var userId = Guid.NewGuid();
        var nowUtc = new DateTime(2026, 4, 17, 14, 0, 0, DateTimeKind.Utc);
        var (svc, fcm, db) = BuildService(nameof(SendToUser_WhenDailyCapHit_Critical_StillSends), nowUtc);
        await SeedTokenAsync(db, userId);

        var todayStart = new DateTime(nowUtc.Year, nowUtc.Month, nowUtc.Day, 0, 0, 0, DateTimeKind.Utc);
        for (var i = 0; i < 5; i++)
        {
            db.Set<NotificationLog>().Add(new NotificationLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Category = "seed",
                Title = "t",
                Body = "b",
                IsCritical = false,
                SentAt = todayStart.AddHours(i + 1),
                Outcome = NotificationOutcome.Sent
            });
        }
        await db.SaveChangesAsync();

        var result = await svc.SendToUserAsync(userId, "cat", "t", "b", isCritical: true);

        Assert.True(result.Sent);
        Assert.Equal(1, fcm.SendCallCount);
    }

    // ── Happy path ───────────────────────────────────────────────────────────

    [Fact]
    public async Task SendToUser_HappyPath_SendsAndUpdatesLastUsedAt()
    {
        var userId = Guid.NewGuid();
        var nowUtc = new DateTime(2026, 4, 17, 12, 0, 0, DateTimeKind.Utc);
        var (svc, fcm, db) = BuildService(nameof(SendToUser_HappyPath_SendsAndUpdatesLastUsedAt), nowUtc);
        await SeedTokenAsync(db, userId, "tok-happy");

        var result = await svc.SendToUserAsync(userId, "cat", "t", "b");

        Assert.True(result.Sent);
        Assert.Equal("Sent", result.Reason);
        Assert.Equal(1, fcm.SendCallCount);
        var tok = await db.Set<DeviceToken>().SingleAsync(t => t.Token == "tok-happy");
        Assert.Equal(nowUtc, tok.LastUsedAt);
        Assert.True(tok.IsActive);
    }

    // ── Invalid token deactivation ───────────────────────────────────────────

    [Fact]
    public async Task SendToUser_WhenFcmReportsTokenInvalid_TokenIsDeactivated()
    {
        var userId = Guid.NewGuid();
        var nowUtc = new DateTime(2026, 4, 17, 12, 0, 0, DateTimeKind.Utc);
        var (svc, fcm, db) = BuildService(nameof(SendToUser_WhenFcmReportsTokenInvalid_TokenIsDeactivated), nowUtc);
        await SeedTokenAsync(db, userId, "tok-dead");
        fcm.ResultForToken = _ => new FcmSendResult(false, true, "Unregistered");

        var result = await svc.SendToUserAsync(userId, "cat", "t", "b");

        Assert.False(result.Sent);
        Assert.Equal("FcmError", result.Reason);
        var tok = await db.Set<DeviceToken>().SingleAsync(t => t.Token == "tok-dead");
        Assert.False(tok.IsActive);
    }

    // ── Register / Unregister ────────────────────────────────────────────────

    [Fact]
    public async Task RegisterToken_NewToken_Inserts()
    {
        var userId = Guid.NewGuid();
        var (svc, _, db) = BuildService(nameof(RegisterToken_NewToken_Inserts),
            new DateTime(2026, 4, 17, 12, 0, 0, DateTimeKind.Utc));

        await svc.RegisterTokenAsync(userId, "tok-new", DevicePlatform.Android);

        var tok = await db.Set<DeviceToken>().SingleAsync();
        Assert.Equal(userId, tok.UserId);
        Assert.Equal("tok-new", tok.Token);
        Assert.True(tok.IsActive);
        Assert.Equal(DevicePlatform.Android, tok.Platform);
    }

    [Fact]
    public async Task RegisterToken_ExistingForSameUser_ReactivatesAndBumpsLastUsedAt()
    {
        var userId = Guid.NewGuid();
        var nowUtc = new DateTime(2026, 4, 17, 12, 0, 0, DateTimeKind.Utc);
        var (svc, _, db) = BuildService(nameof(RegisterToken_ExistingForSameUser_ReactivatesAndBumpsLastUsedAt), nowUtc);

        db.Set<DeviceToken>().Add(new DeviceToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Token = "tok-existing",
            Platform = DevicePlatform.Android,
            RegisteredAt = nowUtc.AddDays(-7),
            LastUsedAt = nowUtc.AddDays(-7),
            IsActive = false
        });
        await db.SaveChangesAsync();

        await svc.RegisterTokenAsync(userId, "tok-existing", DevicePlatform.iOS);

        var tok = await db.Set<DeviceToken>().SingleAsync();
        Assert.True(tok.IsActive);
        Assert.Equal(nowUtc, tok.LastUsedAt);
        Assert.Equal(DevicePlatform.iOS, tok.Platform);
    }

    [Fact]
    public async Task UnregisterToken_DeactivatesAllMatches()
    {
        var userId = Guid.NewGuid();
        var (svc, _, db) = BuildService(nameof(UnregisterToken_DeactivatesAllMatches),
            new DateTime(2026, 4, 17, 12, 0, 0, DateTimeKind.Utc));
        await SeedTokenAsync(db, userId, "tok-del");

        await svc.UnregisterTokenAsync("tok-del");

        var tok = await db.Set<DeviceToken>().SingleAsync();
        Assert.False(tok.IsActive);
    }
}
