using System.Security.Cryptography;
using System.Text;
using System.Net;
using LifeLevel.Modules.Integrations.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Integrations.Application;
using LifeLevel.Modules.Integrations.Application.UseCases;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace LifeLevel.Api.Tests;

public class StravaWebhookServiceTests
{
    private const string TestClientSecret = "test-client-secret-12345";
    private const string TestWebhookToken = "my-webhook-verify-token";

    private static readonly StravaOptions TestOptions = new()
    {
        ClientId = "12345",
        ClientSecret = TestClientSecret,
        WebhookVerifyToken = TestWebhookToken
    };

    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private static StravaWebhookService CreateService(
        AppDbContext db,
        HttpClient? http = null,
        StravaOAuthService? oAuth = null,
        HealthSyncService? healthSync = null,
        Guid? characterId = null)
    {
        http ??= new HttpClient();
        oAuth ??= new StravaOAuthService(db, http, Options.Create(TestOptions));
        healthSync ??= new HealthSyncService(
            db,
            new StubCharacterIdReadPort(characterId),
            new StubActivityLogPort(),
            new StubActivityExternalIdReadPort());

        var pending = new PendingActivityService(
            db, new StubCharacterIdReadPort(characterId), healthSync,
            new StubActivityGainPreviewPort(), new LifeLevel.SharedKernel.Ports.NoOpNotificationPort());
        return new StravaWebhookService(db, http, oAuth, healthSync, pending, Options.Create(TestOptions));
    }

    // ── VerifyChallenge ──────────────────────────────────────────────────────

    [Fact]
    public void VerifyChallenge_CorrectToken_ReturnsTrue()
    {
        var db = CreateDb(nameof(VerifyChallenge_CorrectToken_ReturnsTrue));
        var service = CreateService(db);

        Assert.True(service.VerifyChallenge(TestWebhookToken));
    }

    [Fact]
    public void VerifyChallenge_WrongToken_ReturnsFalse()
    {
        var db = CreateDb(nameof(VerifyChallenge_WrongToken_ReturnsFalse));
        var service = CreateService(db);

        Assert.False(service.VerifyChallenge("wrong-token"));
    }

    [Fact]
    public void VerifyChallenge_EmptyToken_ReturnsFalse()
    {
        var db = CreateDb(nameof(VerifyChallenge_EmptyToken_ReturnsFalse));
        var service = CreateService(db);

        Assert.False(service.VerifyChallenge(""));
    }

    // ── VerifySignature ──────────────────────────────────────────────────────

    [Fact]
    public void VerifySignature_ValidHmac_ReturnsTrue()
    {
        var db = CreateDb(nameof(VerifySignature_ValidHmac_ReturnsTrue));
        var service = CreateService(db);

        var body = Encoding.UTF8.GetBytes("{\"object_type\":\"activity\"}");
        var hash = HMACSHA256.HashData(Encoding.UTF8.GetBytes(TestClientSecret), body);
        var hex = Convert.ToHexString(hash).ToLowerInvariant();
        var header = $"sha256={hex}";

        Assert.True(service.VerifySignature(header, body));
    }

    [Fact]
    public void VerifySignature_TamperedBody_ReturnsFalse()
    {
        var db = CreateDb(nameof(VerifySignature_TamperedBody_ReturnsFalse));
        var service = CreateService(db);

        var originalBody = Encoding.UTF8.GetBytes("{\"object_type\":\"activity\"}");
        var hash = HMACSHA256.HashData(Encoding.UTF8.GetBytes(TestClientSecret), originalBody);
        var hex = Convert.ToHexString(hash).ToLowerInvariant();
        var header = $"sha256={hex}";

        var tamperedBody = Encoding.UTF8.GetBytes("{\"object_type\":\"HACKED\"}");
        Assert.False(service.VerifySignature(header, tamperedBody));
    }

    [Fact]
    public void VerifySignature_WrongPrefix_ReturnsFalse()
    {
        var db = CreateDb(nameof(VerifySignature_WrongPrefix_ReturnsFalse));
        var service = CreateService(db);

        var body = Encoding.UTF8.GetBytes("test");
        Assert.False(service.VerifySignature("md5=abc123", body));
    }

    [Fact]
    public void VerifySignature_WrongSecret_ReturnsFalse()
    {
        var db = CreateDb(nameof(VerifySignature_WrongSecret_ReturnsFalse));
        var service = CreateService(db);

        var body = Encoding.UTF8.GetBytes("{\"test\":true}");
        var wrongHash = HMACSHA256.HashData(Encoding.UTF8.GetBytes("wrong-secret"), body);
        var hex = Convert.ToHexString(wrongHash).ToLowerInvariant();
        var header = $"sha256={hex}";

        Assert.False(service.VerifySignature(header, body));
    }

    [Fact]
    public void VerifySignature_EmptyBody_StillValidates()
    {
        var db = CreateDb(nameof(VerifySignature_EmptyBody_StillValidates));
        var service = CreateService(db);

        var body = Array.Empty<byte>();
        var hash = HMACSHA256.HashData(Encoding.UTF8.GetBytes(TestClientSecret), body);
        var hex = Convert.ToHexString(hash).ToLowerInvariant();
        var header = $"sha256={hex}";

        Assert.True(service.VerifySignature(header, body));
    }

    // ── ProcessEventAsync ────────────────────────────────────────────────────

    [Fact]
    public async Task ProcessEventAsync_IgnoresNonActivityEvents()
    {
        var db = CreateDb(nameof(ProcessEventAsync_IgnoresNonActivityEvents));
        var service = CreateService(db);

        // "athlete" object type should be ignored — no exception, no crash
        var evt = new StravaWebhookEvent("athlete", 123, "create", 456);
        await service.ProcessEventAsync(evt);
    }

    [Fact]
    public async Task ProcessEventAsync_IgnoresNonCreateAspect()
    {
        var db = CreateDb(nameof(ProcessEventAsync_IgnoresNonCreateAspect));
        var service = CreateService(db);

        // "update" aspect should be ignored
        var evt = new StravaWebhookEvent("activity", 123, "update", 456);
        await service.ProcessEventAsync(evt);
    }

    [Fact]
    public async Task ProcessEventAsync_NoConnection_DoesNothing()
    {
        var db = CreateDb(nameof(ProcessEventAsync_NoConnection_DoesNothing));
        var service = CreateService(db);

        // Valid event but no StravaConnection in DB for this owner
        var evt = new StravaWebhookEvent("activity", 123, "create", 999);
        await service.ProcessEventAsync(evt);
    }

    [Fact]
    public async Task StageRecentAsync_QueuesPastWorkoutsAndDoesNotDuplicateOnRetry()
    {
        var db = CreateDb(nameof(StageRecentAsync_QueuesPastWorkoutsAndDoesNotDuplicateOnRetry));
        var userId = Guid.NewGuid();
        var characterId = Guid.NewGuid();
        db.Set<StravaConnection>().Add(new StravaConnection
        {
            Id = Guid.NewGuid(), UserId = userId, StravaAthleteId = 123,
            AccessToken = "test-token", RefreshToken = "test-refresh",
            ExpiresAt = DateTime.UtcNow.AddHours(1), IsActive = true,
        });
        await db.SaveChangesAsync();

        var started = DateTime.UtcNow.AddDays(-2).ToString("O");
        var json = $$"""
            [{"id":101,"sport_type":"Ride","moving_time":1800,"distance":12000,"calories":250,"start_date_local":"{{started}}"},
             {"id":102,"sport_type":"Workout","moving_time":0,"elapsed_time":2400,"distance":0,"calories":180,"start_date_local":"{{started}}"}]
            """;
        using var http = new HttpClient(new JsonHandler(json));
        var service = CreateService(db, http, characterId: characterId);

        var first = await service.StageRecentAsync(userId);
        var second = await service.StageRecentAsync(userId);

        Assert.Equal(2, first.PendingCount);
        Assert.Equal(2, second.PendingCount);
        Assert.Contains(first.Items, item => item.ActivityType == "Cycling");
        Assert.Contains(first.Items, item => item.ActivityType == "Gym");
        Assert.Contains(first.Items, item => item.ActivityType == "Gym" && item.DurationMinutes == 40);
        Assert.Equal(2, await db.Set<PendingActivity>().CountAsync());
    }

    private sealed class JsonHandler(string json) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken cancellationToken) =>
            Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json"),
            });
    }
}
