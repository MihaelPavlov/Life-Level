using System.Security.Cryptography;
using System.Text;
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
        HealthSyncService? healthSync = null)
    {
        http ??= new HttpClient();
        oAuth ??= new StravaOAuthService(db, http, Options.Create(TestOptions));
        healthSync ??= new HealthSyncService(
            db,
            new StubCharacterIdReadPort(),
            new StubActivityLogPort(),
            new StubActivityExternalIdReadPort());

        return new StravaWebhookService(db, http, oAuth, healthSync, Options.Create(TestOptions));
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
}
