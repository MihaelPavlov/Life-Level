using LifeLevel.Modules.Identity.Application.DTOs;
using LifeLevel.Modules.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Identity.Application.UseCases;

public class AccountService(DbContext db, JwtService jwt)
{
    public async Task<AccountResponse> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await FindUserAsync(userId, ct);
        return new AccountResponse(user.Username, user.Email);
    }

    public async Task<UpdateEmailResponse> UpdateEmailAsync(
        Guid userId,
        UpdateEmailRequest req,
        CancellationToken ct = default)
    {
        var email = NormalizeEmail(req.Email);
        if (string.IsNullOrWhiteSpace(email))
            throw new InvalidOperationException("Email is required.");

        var user = await FindUserAsync(userId, ct);
        VerifyPassword(user, req.CurrentPassword);

        var alreadyUsed = await db.Set<User>()
            .AnyAsync(u => u.Id != userId && u.Email == email, ct);
        if (alreadyUsed)
            throw new InvalidOperationException("Email already in use.");

        user.Email = email;
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

    private async Task<User> FindUserAsync(Guid userId, CancellationToken ct) =>
        await db.Set<User>().FirstOrDefaultAsync(u => u.Id == userId, ct)
        ?? throw new InvalidOperationException("User not found.");

    private static void VerifyPassword(User user, string password)
    {
        if (string.IsNullOrWhiteSpace(password) ||
            !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
            throw new InvalidOperationException("Current password is incorrect.");
    }

    private static string NormalizeEmail(string value) =>
        value.Trim().ToLowerInvariant();
}
