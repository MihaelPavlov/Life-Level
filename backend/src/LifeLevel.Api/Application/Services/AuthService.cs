using LifeLevel.Api.Application.DTOs.Auth;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Domain.Enums;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class AuthService(AppDbContext db, JwtService jwt)
{
    private static readonly RingItemType[] DefaultRing =
    [
        RingItemType.World,
        RingItemType.Guild,
        RingItemType.Stats,
        RingItemType.Battle,
        RingItemType.Titles,
        RingItemType.Boss,
    ];

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
            Role = req.Role,
        };

        var character = new Character { Id = Guid.NewGuid(), UserId = user.Id };

        var ringItems = DefaultRing.Select((type, i) => new UserRingItem
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            ItemType = type,
            SortOrder = i,
        });

        db.Users.Add(user);
        db.Characters.Add(character);
        db.UserRingItems.AddRange(ringItems);
        await db.SaveChangesAsync();

        return new AuthResponse(
            jwt.Generate(user),
            user.Username,
            character.Id,
            DefaultRing,
            false);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest req)
    {
        var user = await db.Users
            .Include(u => u.Character)
            .Include(u => u.RingItems)
            .FirstOrDefaultAsync(u => u.Email == req.Email)
            ?? throw new InvalidOperationException("Invalid email or password.");

        if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            throw new InvalidOperationException("Invalid email or password.");

        var ring = user.RingItems.Any()
            ? user.RingItems.OrderBy(r => r.SortOrder).Select(r => r.ItemType).ToList()
            : DefaultRing.ToList();

        return new AuthResponse(jwt.Generate(user), user.Username, user.Character!.Id, ring, user.Character!.IsSetupComplete);
    }
}
