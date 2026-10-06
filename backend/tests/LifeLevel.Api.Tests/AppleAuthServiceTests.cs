using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Identity.Application.DTOs;
using LifeLevel.Modules.Identity.Application.Ports.Out;
using LifeLevel.Modules.Identity.Application.UseCases;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Identity.Infrastructure;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace LifeLevel.Api.Tests;

public class AppleAuthServiceTests
{
    [Fact]
    public async Task Apple_NewIdentity_CreatesPlayerOnceAndSignsInAfter()
    {
        await using var db = CreateDb();
        var events = new CapturingEvents();
        var service = CreateService(db, new StubAppleVerifier("apple-1", "Relay@PrivateRelay.AppleId.com"), events);

        var first = await service.AppleAsync(new AppleAuthRequest("token", "nonce"));
        var second = await service.AppleAsync(new AppleAuthRequest("token", "nonce"));

        var user = Assert.Single(db.Users);
        Assert.Equal("relay@privaterelay.appleid.com", user.NormalizedEmail);
        Assert.Null(user.PasswordHash);
        Assert.StartsWith("Player", user.Username);
        Assert.Equal(first.Username, second.Username);
        var login = Assert.Single(db.UserExternalLogins);
        Assert.Equal(AuthService.AppleProvider, login.Provider);
        Assert.Equal(1, events.RegisteredCount);
    }

    [Fact]
    public async Task Apple_LaterSignInWithoutEmail_StillFindsTheLinkedAccount()
    {
        await using var db = CreateDb();
        var service = CreateService(db, new StubAppleVerifier("apple-2", "first@example.com"), new CapturingEvents());
        var created = await service.AppleAsync(new AppleAuthRequest("token"));

        var noEmail = CreateService(db, new StubAppleVerifier("apple-2", null), new CapturingEvents());
        var again = await noEmail.AppleAsync(new AppleAuthRequest("token"));

        Assert.Equal(created.Username, again.Username);
        Assert.Single(db.Users);
    }

    [Fact]
    public async Task Apple_NewIdentityWithoutEmail_IsRejected()
    {
        await using var db = CreateDb();
        var service = CreateService(db, new StubAppleVerifier("apple-3", null), new CapturingEvents());

        await Assert.ThrowsAsync<ExternalEmailMissingException>(() =>
            service.AppleAsync(new AppleAuthRequest("token")));
        Assert.Empty(db.Users);
    }

    [Fact]
    public async Task Apple_ExistingEmail_RequiresAndVerifiesPasswordBeforeLinking()
    {
        await using var db = CreateDb();
        var user = new User
        {
            Username = "existing",
            Email = "existing@example.com",
            NormalizedEmail = "existing@example.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("correct-password"),
        };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        var service = CreateService(db, new StubAppleVerifier("apple-existing", "EXISTING@example.com"), new CapturingEvents());

        var linkRequired = await Assert.ThrowsAsync<AppleAccountLinkRequiredException>(() =>
            service.AppleAsync(new AppleAuthRequest("token")));
        Assert.Contains("connect Apple", linkRequired.Message);
        await Assert.ThrowsAsync<InvalidAppleLinkPasswordException>(() =>
            service.AppleAsync(new AppleAuthRequest("token", null, "wrong")));

        var result = await service.AppleAsync(new AppleAuthRequest("token", null, "correct-password"));

        Assert.Equal("existing", result.Username);
        var login = Assert.Single(db.UserExternalLogins);
        Assert.Equal(user.Id, login.UserId);
        Assert.Equal(AuthService.AppleProvider, login.Provider);
    }

    [Fact]
    public async Task Apple_AndGoogle_CanBothLinkToOneAccount()
    {
        await using var db = CreateDb();
        var user = new User
        {
            Username = "both",
            Email = "both@example.com",
            NormalizedEmail = "both@example.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("pw-123456"),
        };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        var service = new AuthService(db, Jwt(), new CapturingEvents(), new NullCharacterInfo(),
            new StubGoogleVerifier("google-both", "both@example.com"),
            new StubAppleVerifier("apple-both", "both@example.com"));

        await service.GoogleAsync(new GoogleAuthRequest("token", "pw-123456"));
        await service.AppleAsync(new AppleAuthRequest("token", null, "pw-123456"));

        Assert.Equal(2, db.UserExternalLogins.Count(x => x.UserId == user.Id));
    }

    [Fact]
    public void NonceHash_MatchesAppleFormat()
    {
        // Apple stores the lowercase hex SHA-256 of the app's raw nonce.
        Assert.Equal(
            "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
            AppleTokenVerifier.Sha256Hex("hello"));
    }

    private static AppDbContext CreateDb() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString())
        .Options);

    private static AuthService CreateService(AppDbContext db, IAppleTokenVerifier apple, IEventPublisher events) =>
        new(db, Jwt(), events, new NullCharacterInfo(), new StubGoogleVerifier(), apple);

    private static JwtService Jwt() => new(new ConfigurationBuilder()
        .AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = "test-key-that-is-long-enough-for-hmac-sha256-signing",
            ["Jwt:Issuer"] = "tests",
            ["Jwt:Audience"] = "tests",
        })
        .Build());

    private sealed class StubAppleVerifier(string subject, string? email) : IAppleTokenVerifier
    {
        public Task<AppleIdentity> VerifyAsync(string identityToken, string? rawNonce, CancellationToken ct = default) =>
            Task.FromResult(new AppleIdentity(subject, email, false));
    }

    private sealed class StubGoogleVerifier(
        string subject = "google-test",
        string email = "test@example.com") : IGoogleTokenVerifier
    {
        public Task<GoogleIdentity> VerifyAsync(string idToken, CancellationToken ct = default) =>
            Task.FromResult(new GoogleIdentity(subject, email, true, DateTimeOffset.UtcNow));
    }

    private sealed class NullCharacterInfo : ICharacterInfoPort
    {
        public Task<CharacterInfoDto?> GetByUserIdAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult<CharacterInfoDto?>(null);
    }

    private sealed class CapturingEvents : IEventPublisher
    {
        public int RegisteredCount { get; private set; }

        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
            where TEvent : IDomainEvent
        {
            if (e is UserRegisteredEvent) RegisteredCount++;
            return Task.CompletedTask;
        }
    }
}
