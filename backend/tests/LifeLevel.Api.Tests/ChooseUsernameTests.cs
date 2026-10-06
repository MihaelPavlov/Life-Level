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

public class ChooseUsernameTests
{
    [Fact]
    public async Task GoogleSignUp_FlagsTheGeneratedName_PasswordSignUpDoesNot()
    {
        await using var db = CreateDb();
        var auth = CreateAuth(db);

        var google = await auth.GoogleAsync(new GoogleAuthRequest("token"));
        var password = await auth.RegisterAsync(new RegisterRequest("typed", "typed@example.com", "pw-123456"));

        Assert.True(google.NeedsUsername);
        Assert.False(password.NeedsUsername);
    }

    [Fact]
    public async Task ChoosingAName_RenamesAndClearsTheFlag()
    {
        await using var db = CreateDb();
        var created = await CreateAuth(db).GoogleAsync(new GoogleAuthRequest("token"));
        var user = Assert.Single(db.Users);

        var result = await Account(db).ChooseUsernameAsync(user.Id, new ChooseUsernameRequest("  SwiftFalcon "));

        Assert.Equal("SwiftFalcon", result.Username);
        Assert.Equal("SwiftFalcon", user.Username);
        Assert.False(user.NeedsUsername);
        Assert.NotEqual(created.Token, result.Token);
        var again = await CreateAuth(db).GoogleAsync(new GoogleAuthRequest("token"));
        Assert.False(again.NeedsUsername);
    }

    [Fact]
    public async Task KeepingTheGeneratedName_ClearsTheFlag()
    {
        await using var db = CreateDb();
        var created = await CreateAuth(db).GoogleAsync(new GoogleAuthRequest("token"));
        var user = Assert.Single(db.Users);

        await Account(db).ChooseUsernameAsync(user.Id, new ChooseUsernameRequest(created.Username));

        Assert.Equal(created.Username, user.Username);
        Assert.False(user.NeedsUsername);
    }

    [Theory]
    [InlineData("ab", "At least 3 characters.")]
    [InlineData("abcdefghijklmnopqrstu", "20 characters at most.")]
    [InlineData("bad name", "Only letters, numbers and _.")]
    [InlineData("ALEX", "That name is taken.")]
    public async Task BadNames_AreRejectedWithAReason(string name, string reason)
    {
        await using var db = CreateDb();
        db.Users.Add(new User { Username = "alex", Email = "alex@example.com", NormalizedEmail = "alex@example.com" });
        var me = new User { Username = "PlayerAAAA", Email = "me@example.com", NormalizedEmail = "me@example.com", NeedsUsername = true };
        db.Users.Add(me);
        await db.SaveChangesAsync();
        var account = Account(db);

        Assert.Equal(reason, await account.UsernameProblemAsync(me.Id, name));
        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            account.ChooseUsernameAsync(me.Id, new ChooseUsernameRequest(name)));
        Assert.Equal(reason, error.Message);
        Assert.True(me.NeedsUsername);
    }

    [Fact]
    public async Task YourOwnName_IsAvailableToYou()
    {
        await using var db = CreateDb();
        var me = new User { Username = "Runner_7", Email = "me@example.com", NormalizedEmail = "me@example.com" };
        db.Users.Add(me);
        await db.SaveChangesAsync();

        Assert.Null(await Account(db).UsernameProblemAsync(me.Id, "runner_7"));
    }

    private static AppDbContext CreateDb() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString())
        .Options);

    private static AuthService CreateAuth(AppDbContext db) =>
        new(db, Jwt(), new NoEvents(), new NullCharacterInfo(), new StubGoogleVerifier(), new UnusedAppleVerifier());

    private static AccountService Account(AppDbContext db) => new(db, Jwt(), new StubGoogleVerifier());

    private static JwtService Jwt() => new(new ConfigurationBuilder()
        .AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Jwt:Key"] = "test-key-that-is-long-enough-for-hmac-sha256-signing",
            ["Jwt:Issuer"] = "tests",
            ["Jwt:Audience"] = "tests",
        })
        .Build());

    private sealed class StubGoogleVerifier : IGoogleTokenVerifier
    {
        public Task<GoogleIdentity> VerifyAsync(string idToken, CancellationToken ct = default) =>
            Task.FromResult(new GoogleIdentity("google-name", "name@example.com", true, DateTimeOffset.UtcNow));
    }

    private sealed class UnusedAppleVerifier : IAppleTokenVerifier
    {
        public Task<AppleIdentity> VerifyAsync(string identityToken, string? rawNonce, CancellationToken ct = default) =>
            throw new InvalidOperationException("Not used.");
    }

    private sealed class NullCharacterInfo : ICharacterInfoPort
    {
        public Task<CharacterInfoDto?> GetByUserIdAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult<CharacterInfoDto?>(null);
    }

    private sealed class NoEvents : IEventPublisher
    {
        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default) where TEvent : IDomainEvent =>
            Task.CompletedTask;
    }
}
