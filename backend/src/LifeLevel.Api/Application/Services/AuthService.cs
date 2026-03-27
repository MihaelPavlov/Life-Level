using LifeLevel.Api.Application.DTOs.Auth;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class AuthService(AppDbContext db, JwtService jwt)
{
    public async Task<AuthResponse> RegisterAsync(RegisterRequest req)
    {
        if (await db.Users.AnyAsync(u => u.Email == req.Email))
            throw new InvalidOperationException("Email already in use.");

        if (await db.Users.AnyAsync(u => u.Username == req.Username))
            throw new InvalidOperationException("Username already taken.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = req.Username,
            Email = req.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
        };

        var character = new Character
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
        };

        db.Users.Add(user);
        db.Characters.Add(character);
        await db.SaveChangesAsync();

        return new AuthResponse(jwt.Generate(user), user.Username, character.Id);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest req)
    {
        var user = await db.Users
            .Include(u => u.Character)
            .FirstOrDefaultAsync(u => u.Email == req.Email)
            ?? throw new InvalidOperationException("Invalid email or password.");

        if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            throw new InvalidOperationException("Invalid email or password.");

        return new AuthResponse(jwt.Generate(user), user.Username, user.Character!.Id);
    }
}
