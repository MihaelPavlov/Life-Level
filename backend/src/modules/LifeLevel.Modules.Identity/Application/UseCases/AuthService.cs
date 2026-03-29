using LifeLevel.Modules.Identity.Application.DTOs;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Identity.Application.UseCases;

public class AuthService(DbContext db, JwtService jwt, IEventPublisher events, ICharacterInfoPort characterInfo)
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
        if (await db.Set<User>().AnyAsync(u => u.Email == req.Email))
            throw new InvalidOperationException("Email already in use.");

        if (await db.Set<User>().AnyAsync(u => u.Username == req.Username))
            throw new InvalidOperationException("Username already taken.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = req.Username,
            Email = req.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            Role = req.Role,
        };

        var ringItems = DefaultRing.Select((type, i) => new UserRingItem
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            ItemType = type,
            SortOrder = i,
        });

        db.Set<User>().Add(user);
        db.Set<UserRingItem>().AddRange(ringItems);
        await db.SaveChangesAsync();

        // Publish event — CharacterCreatedHandler in Character module creates the Character row
        await events.PublishAsync(new UserRegisteredEvent(user.Id, user.Username));

        var charInfo = await characterInfo.GetByUserIdAsync(user.Id);

        return new AuthResponse(
            jwt.Generate(user),
            user.Username,
            charInfo?.CharacterId,
            DefaultRing,
            charInfo?.IsSetupComplete ?? false);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest req)
    {
        var user = await db.Set<User>()
            .Include(u => u.RingItems)
            .FirstOrDefaultAsync(u => u.Email == req.Email)
            ?? throw new InvalidOperationException("Invalid email or password.");

        if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            throw new InvalidOperationException("Invalid email or password.");

        var ring = user.RingItems.Any()
            ? user.RingItems.OrderBy(r => r.SortOrder).Select(r => r.ItemType).ToList()
            : DefaultRing.ToList();

        var charInfo = await characterInfo.GetByUserIdAsync(user.Id);

        return new AuthResponse(
            jwt.Generate(user),
            user.Username,
            charInfo?.CharacterId,
            ring,
            charInfo?.IsSetupComplete ?? false);
    }
}
