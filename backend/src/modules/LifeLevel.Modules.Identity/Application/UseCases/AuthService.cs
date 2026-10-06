using System.Security.Cryptography;
using System.Text;
using LifeLevel.Modules.Identity.Application.DTOs;
using LifeLevel.Modules.Identity.Application.Ports.Out;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Identity.Application.UseCases;

public class AuthService(
    DbContext db,
    JwtService jwt,
    IEventPublisher events,
    ICharacterInfoPort characterInfo,
    IGoogleTokenVerifier googleTokens,
    IAppleTokenVerifier appleTokens)
{
    public const string GoogleProvider = "google";
    public const string AppleProvider = "apple";

    private static readonly RingItemType[] DefaultRing =
    [
        RingItemType.World, RingItemType.Guild, RingItemType.Stats,
        RingItemType.Battle, RingItemType.Titles, RingItemType.Boss,
    ];

    public async Task<AuthResponse> RegisterAsync(RegisterRequest req)
    {
        var email = NormalizeEmail(req.Email);
        if (await db.Set<User>().AnyAsync(u => u.NormalizedEmail == email))
            throw new InvalidOperationException("Email already in use.");
        if (await db.Set<User>().AnyAsync(u => u.Username == req.Username))
            throw new InvalidOperationException("Username already taken.");

        return await CreateUserAsync(new User
        {
            Id = Guid.NewGuid(),
            Username = req.Username,
            Email = email,
            NormalizedEmail = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            Role = req.Role,
        });
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest req)
    {
        var identifier = req.EmailOrUsername.Trim();
        var normalizedEmail = NormalizeEmail(identifier);
        var user = await db.Set<User>()
            .Include(u => u.RingItems)
            .FirstOrDefaultAsync(u =>
                u.NormalizedEmail == normalizedEmail || u.Username == identifier)
            ?? throw new InvalidOperationException("Invalid email/username or password.");

        if (string.IsNullOrWhiteSpace(user.PasswordHash) ||
            !BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            throw new InvalidOperationException("Invalid email/username or password.");

        return await BuildResponseAsync(user);
    }

    public async Task<AuthResponse> GoogleAsync(
        GoogleAuthRequest req,
        CancellationToken ct = default)
    {
        var identity = await googleTokens.VerifyAsync(req.IdToken, ct);
        return await ExternalSignInAsync(
            GoogleProvider, identity.Subject, identity.Email, req.CurrentPassword,
            () => new GoogleAccountLinkRequiredException(),
            () => new InvalidGoogleLinkPasswordException(),
            ct);
    }

    public async Task<AuthResponse> AppleAsync(
        AppleAuthRequest req,
        CancellationToken ct = default)
    {
        var identity = await appleTokens.VerifyAsync(req.IdentityToken, req.Nonce, ct);
        return await ExternalSignInAsync(
            AppleProvider, identity.Subject, identity.Email, req.CurrentPassword,
            () => new AppleAccountLinkRequiredException(),
            () => new InvalidAppleLinkPasswordException(),
            ct);
    }

    /// <summary>
    /// Shared by every external provider: an existing link signs in, a matching
    /// email links after the account password is confirmed, otherwise a new
    /// password-less player is created.
    /// </summary>
    private async Task<AuthResponse> ExternalSignInAsync(
        string provider,
        string subject,
        string? providerEmail,
        string? currentPassword,
        Func<Exception> linkRequired,
        Func<Exception> badLinkPassword,
        CancellationToken ct)
    {
        var externalLogin = await FindExternalLoginAsync(provider, subject, ct);
        if (externalLogin is not null)
            return await BuildResponseAsync(externalLogin.User);

        // Apple may hide the email; without one we can neither match nor create.
        if (string.IsNullOrWhiteSpace(providerEmail))
            throw new ExternalEmailMissingException();

        var email = NormalizeEmail(providerEmail);
        var existingUser = await db.Set<User>()
            .Include(u => u.RingItems)
            .FirstOrDefaultAsync(u => u.NormalizedEmail == email, ct);
        if (existingUser is not null)
        {
            if (string.IsNullOrWhiteSpace(currentPassword))
                throw linkRequired();
            if (string.IsNullOrWhiteSpace(existingUser.PasswordHash) ||
                !BCrypt.Net.BCrypt.Verify(currentPassword, existingUser.PasswordHash))
                throw badLinkPassword();

            db.Set<UserExternalLogin>().Add(new UserExternalLogin
            {
                UserId = existingUser.Id,
                Provider = provider,
                ProviderSubject = subject,
            });
            try
            {
                await db.SaveChangesAsync(ct);
            }
            catch (DbUpdateException)
            {
                DetachAddedEntries();
                var winner = await FindExternalLoginAsync(provider, subject, ct);
                if (winner?.UserId != existingUser.Id) throw;
            }
            return await BuildResponseAsync(existingUser);
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = await GenerateUsernameAsync(provider, subject, ct),
            Email = email,
            NormalizedEmail = email,
            PasswordHash = null,
            Role = UserRole.Player,
            NeedsUsername = true,
            ExternalLogins =
            [
                new UserExternalLogin
                {
                    Provider = provider,
                    ProviderSubject = subject,
                }
            ],
        };
        try
        {
            return await CreateUserAsync(user, ct);
        }
        catch (DbUpdateException)
        {
            DetachAddedEntries();
            var winner = await FindExternalLoginAsync(provider, subject, ct);
            if (winner is null) throw;
            return await BuildResponseAsync(winner.User);
        }
    }

    private async Task<AuthResponse> CreateUserAsync(User user, CancellationToken ct = default)
    {
        var ringItems = DefaultRing.Select((type, i) => new UserRingItem
        {
            Id = Guid.NewGuid(), UserId = user.Id, ItemType = type, SortOrder = i,
        }).ToList();
        db.Set<User>().Add(user);
        db.Set<UserRingItem>().AddRange(ringItems);
        await db.SaveChangesAsync(ct);
        await events.PublishAsync(new UserRegisteredEvent(user.Id, user.Username), ct);
        user.RingItems = ringItems;
        return await BuildResponseAsync(user);
    }

    private async Task<AuthResponse> BuildResponseAsync(User user)
    {
        var ring = user.RingItems.Count != 0
            ? user.RingItems.OrderBy(r => r.SortOrder).Select(r => r.ItemType).ToList()
            : DefaultRing.ToList();
        var charInfo = await characterInfo.GetByUserIdAsync(user.Id);
        return new AuthResponse(jwt.Generate(user), user.Username, charInfo?.CharacterId,
            ring, charInfo?.IsSetupComplete ?? false, user.NeedsUsername);
    }

    private async Task<string> GenerateUsernameAsync(string provider, string subject, CancellationToken ct)
    {
        var digest = SHA256.HashData(Encoding.UTF8.GetBytes($"{provider}:{subject}"));
        const string alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        var suffix = new string(digest.Take(10).Select(x => alphabet[x % alphabet.Length]).ToArray());
        for (var length = 4; length <= suffix.Length; length++)
        {
            var candidate = $"Player{suffix[..length]}";
            if (!await db.Set<User>().AnyAsync(u => u.Username == candidate, ct))
                return candidate;
        }
        return $"Player{Guid.NewGuid():N}"[..18];
    }

    private Task<UserExternalLogin?> FindExternalLoginAsync(
        string provider,
        string subject,
        CancellationToken ct) => db.Set<UserExternalLogin>()
        .Include(x => x.User)
        .ThenInclude(u => u.RingItems)
        .FirstOrDefaultAsync(
            x => x.Provider == provider && x.ProviderSubject == subject,
            ct);

    private void DetachAddedEntries()
    {
        foreach (var entry in db.ChangeTracker.Entries()
                     .Where(x => x.State == EntityState.Added).ToList())
            entry.State = EntityState.Detached;
    }

    public static string NormalizeEmail(string value) => value.Trim().ToLowerInvariant();
}

/// <summary>An external sign-in matched an existing email; its password must be confirmed to link.</summary>
public abstract class AccountLinkRequiredException(string provider)
    : Exception($"An account with this email already exists. Enter its password to connect {provider}.");

/// <summary>The password given to link an external sign-in was wrong.</summary>
public abstract class InvalidLinkPasswordException()
    : Exception("The current password is incorrect.");

public sealed class GoogleAccountLinkRequiredException() : AccountLinkRequiredException("Google");

public sealed class InvalidGoogleLinkPasswordException : InvalidLinkPasswordException;

public sealed class AppleAccountLinkRequiredException() : AccountLinkRequiredException("Apple");

public sealed class InvalidAppleLinkPasswordException : InvalidLinkPasswordException;

public sealed class ExternalEmailMissingException()
    : Exception("Your account didn't share an email address. Allow email sharing and try again.");
