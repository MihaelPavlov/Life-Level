using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Identity.Application.DTOs;
using LifeLevel.Modules.Identity.Application.Ports.Out;
using LifeLevel.Modules.Identity.Application.UseCases;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace LifeLevel.Api.Tests;

public class GoogleAuthServiceTests
{
    [Fact]
    public async Task Google_NewIdentity_CreatesPlayerAndCanReturn()
    {
        await using var db = CreateDb();
        var events = new CapturingEvents();
        var verifier = new StubGoogleVerifier("google-1", "PLAYER@EXAMPLE.COM");
        var service = CreateService(db, verifier, events);

        var first = await service.GoogleAsync(new GoogleAuthRequest("token"));
        var second = await service.GoogleAsync(new GoogleAuthRequest("token"));

        var user = Assert.Single(db.Users);
        Assert.Equal("player@example.com", user.NormalizedEmail);
        Assert.Null(user.PasswordHash);
        Assert.StartsWith("Player", user.Username);
        Assert.Equal(first.Username, second.Username);
        Assert.Single(db.UserExternalLogins);
        Assert.Equal(1, events.RegisteredCount);
    }

    [Fact]
    public async Task Google_ExistingEmail_RequiresAndVerifiesPasswordBeforeLinking()
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
        var service = CreateService(
            db,
            new StubGoogleVerifier("google-existing", "EXISTING@example.com"),
            new CapturingEvents());

        await Assert.ThrowsAsync<GoogleAccountLinkRequiredException>(() =>
            service.GoogleAsync(new GoogleAuthRequest("token")));
        await Assert.ThrowsAsync<InvalidGoogleLinkPasswordException>(() =>
            service.GoogleAsync(new GoogleAuthRequest("token", "wrong")));

        var result = await service.GoogleAsync(
            new GoogleAuthRequest("token", "correct-password"));

        Assert.Equal("existing", result.Username);
        var login = Assert.Single(db.UserExternalLogins);
        Assert.Equal(user.Id, login.UserId);
    }

    [Fact]
    public async Task PasswordLogin_GoogleOnlyAccount_IsRejectedCleanly()
    {
        await using var db = CreateDb();
        db.Users.Add(new User
        {
            Username = "PlayerTEST",
            Email = "google@example.com",
            NormalizedEmail = "google@example.com",
            PasswordHash = null,
        });
        await db.SaveChangesAsync();
        var service = CreateService(db, new StubGoogleVerifier(), new CapturingEvents());

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.LoginAsync(new LoginRequest("google@example.com", "anything")));

        Assert.Equal("Invalid email/username or password.", error.Message);
    }

    [Fact]
    public async Task SetPasswordWithGoogle_RequiresMatchingRecentIdentity()
    {
        await using var db = CreateDb();
        var user = new User
        {
            Username = "PlayerPASS",
            Email = "pass@example.com",
            NormalizedEmail = "pass@example.com",
            ExternalLogins =
            [
                new UserExternalLogin
                {
                    Provider = AuthService.GoogleProvider,
                    ProviderSubject = "google-pass",
                }
            ],
        };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        var verifier = new StubGoogleVerifier("google-pass", "pass@example.com");
        var account = new AccountService(db, Jwt(), verifier);

        await account.SetPasswordWithGoogleAsync(user.Id,
            new SetPasswordWithGoogleRequest("token", "new-password", "new-password"));

        Assert.True(BCrypt.Net.BCrypt.Verify("new-password", user.PasswordHash));
        var info = await account.GetAsync(user.Id);
        Assert.True(info.HasPassword);
        Assert.True(info.GoogleConnected);
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static AuthService CreateService(
        AppDbContext db,
        IGoogleTokenVerifier verifier,
        IEventPublisher events) =>
        new(db, Jwt(), events, new NullCharacterInfo(), verifier, new UnusedAppleVerifier());

    private static JwtService Jwt() => new(new ConfigurationBuilder()
        .AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = "test-key-that-is-long-enough-for-hmac-sha256-signing",
            ["Jwt:Issuer"] = "tests",
            ["Jwt:Audience"] = "tests",
        })
        .Build());

    private sealed class StubGoogleVerifier(
        string subject = "google-test",
        string email = "test@example.com") : IGoogleTokenVerifier
    {
        public Task<GoogleIdentity> VerifyAsync(string idToken, CancellationToken ct = default) =>
            Task.FromResult(new GoogleIdentity(
                subject, email, true, DateTimeOffset.UtcNow));
    }

    private sealed class UnusedAppleVerifier : IAppleTokenVerifier
    {
        public Task<AppleIdentity> VerifyAsync(string identityToken, string? rawNonce, CancellationToken ct = default) =>
            throw new InvalidOperationException("Apple sign-in is not used in these tests.");
    }

    private sealed class NullCharacterInfo : ICharacterInfoPort
    {
        public Task<CharacterInfoDto?> GetByUserIdAsync(
            Guid userId,
            CancellationToken ct = default) => Task.FromResult<CharacterInfoDto?>(null);
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
