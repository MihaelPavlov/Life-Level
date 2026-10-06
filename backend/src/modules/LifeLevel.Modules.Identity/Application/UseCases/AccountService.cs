using LifeLevel.Modules.Identity.Application.DTOs;
using LifeLevel.Modules.Identity.Application.Ports.Out;
using LifeLevel.Modules.Identity.Domain.Entities;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Identity.Application.UseCases;

public class AccountService(DbContext db, JwtService jwt, IGoogleTokenVerifier googleTokens)
{
    public async Task<AccountResponse> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await db.Set<User>()
            .Include(u => u.ExternalLogins)
            .FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new InvalidOperationException("User not found.");
        return new AccountResponse(
            user.Username,
            user.Email,
            !string.IsNullOrWhiteSpace(user.PasswordHash),
            user.ExternalLogins.Any(x => x.Provider == AuthService.GoogleProvider));
    }

    /// <summary>3–20 letters, numbers or underscores.</summary>
    public static readonly Regex UsernamePattern = new("^[A-Za-z0-9_]{3,20}$", RegexOptions.Compiled);

    /// <summary>Null when the name can be used, else why not.</summary>
    public async Task<string?> UsernameProblemAsync(
        Guid userId,
        string? username,
        CancellationToken ct = default)
    {
        var name = username?.Trim() ?? string.Empty;
        if (name.Length < 3) return "At least 3 characters.";
        if (name.Length > 20) return "20 characters at most.";
        if (!UsernamePattern.IsMatch(name)) return "Only letters, numbers and _.";
        // Case-insensitive, so "Alex" and "alex" can't both exist.
        var lower = name.ToLowerInvariant();
        var taken = await db.Set<User>()
            .AnyAsync(u => u.Id != userId && u.Username.ToLower() == lower, ct);
        return taken ? "That name is taken." : null;
    }

    /// <summary>
    /// Sets the player's name (or keeps the current one) and clears
    /// <see cref="User.NeedsUsername"/>. Returns a fresh token, since the name is a claim.
    /// </summary>
    public async Task<ChooseUsernameResponse> ChooseUsernameAsync(
        Guid userId,
        ChooseUsernameRequest req,
        CancellationToken ct = default)
    {
        var user = await FindUserAsync(userId, ct);
        var name = req.Username?.Trim() ?? string.Empty;
        if (name != user.Username)
        {
            var problem = await UsernameProblemAsync(userId, name, ct);
            if (problem is not null) throw new InvalidOperationException(problem);
            user.Username = name;
        }
        user.NeedsUsername = false;
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // Someone claimed it between the check and the save.
            throw new InvalidOperationException("That name is taken.");
        }
        return new ChooseUsernameResponse(jwt.Generate(user), user.Username);
    }

    public async Task<UpdateEmailResponse> UpdateEmailAsync(
        Guid userId,
        UpdateEmailRequest req,
        CancellationToken ct = default)
    {
        var email = AuthService.NormalizeEmail(req.Email);
        if (string.IsNullOrWhiteSpace(email))
            throw new InvalidOperationException("Email is required.");

        var user = await FindUserAsync(userId, ct);
        VerifyPassword(user, req.CurrentPassword);

        var alreadyUsed = await db.Set<User>()
            .AnyAsync(u => u.Id != userId && u.NormalizedEmail == email, ct);
        if (alreadyUsed)
            throw new InvalidOperationException("Email already in use.");

        user.Email = email;
        user.NormalizedEmail = email;
        await db.SaveChangesAsync(ct);

        return new UpdateEmailResponse(jwt.Generate(user), user.Username, user.Email);
    }

    public async Task ChangePasswordAsync(
        Guid userId,
        ChangePasswordRequest req,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(req.NewPassword) || req.NewPassword.Length < 8)
            throw new InvalidOperationException("New password must be at least 8 characters.");

        if (req.NewPassword != req.ConfirmPassword)
            throw new InvalidOperationException("New password confirmation does not match.");

        var user = await FindUserAsync(userId, ct);
        VerifyPassword(user, req.CurrentPassword);

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.NewPassword);
        await db.SaveChangesAsync(ct);
    }

    public async Task SetPasswordWithGoogleAsync(
        Guid userId,
        SetPasswordWithGoogleRequest req,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(req.NewPassword) || req.NewPassword.Length < 8)
            throw new InvalidOperationException("New password must be at least 8 characters.");
        if (req.NewPassword != req.ConfirmPassword)
            throw new InvalidOperationException("New password confirmation does not match.");

        var user = await db.Set<User>()
            .Include(u => u.ExternalLogins)
            .FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new InvalidOperationException("User not found.");
        if (!string.IsNullOrWhiteSpace(user.PasswordHash))
            throw new InvalidOperationException("This account already has a password.");

        var identity = await googleTokens.VerifyAsync(req.GoogleIdToken, ct);
        var linked = user.ExternalLogins.Any(x =>
            x.Provider == AuthService.GoogleProvider && x.ProviderSubject == identity.Subject);
        if (!linked)
            throw new InvalidOperationException("Google identity does not match this account.");

        var tokenAge = DateTimeOffset.UtcNow - identity.IssuedAt;
        if (tokenAge < TimeSpan.FromMinutes(-1) || tokenAge > TimeSpan.FromMinutes(5))
            throw new InvalidOperationException(
                "Please sign in with Google again before setting a password.");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.NewPassword);
        await db.SaveChangesAsync(ct);
    }

    private async Task<User> FindUserAsync(Guid userId, CancellationToken ct) =>
        await db.Set<User>().FirstOrDefaultAsync(u => u.Id == userId, ct)
        ?? throw new InvalidOperationException("User not found.");

    private static void VerifyPassword(User user, string password)
    {
        if (string.IsNullOrWhiteSpace(password) ||
            string.IsNullOrWhiteSpace(user.PasswordHash) ||
            !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
            throw new InvalidOperationException("Current password is incorrect.");
    }

}
