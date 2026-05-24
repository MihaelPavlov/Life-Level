using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public class AdminUserSeeder(AppDbContext db, IConfiguration config)
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

    public async Task SeedAsync()
    {
        var email = config["Admin:Email"] ?? "local@lifelevel.com";
        var password = config["Admin:Password"] ?? "1qaz!QAZ";

        if (await db.Users.AnyAsync(u => u.Email == email))
            return;

        // Derive a username from the email prefix so it never conflicts with existing accounts.
        var username = "admin_" + email.Split('@')[0];

        var userId = Guid.NewGuid();
        var user = new User
        {
            Id = userId,
            Username = username,
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            Role = UserRole.Admin,
        };

        var ringItems = DefaultRing.Select((type, i) => new UserRingItem
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ItemType = type,
            SortOrder = i,
        });

        db.Users.Add(user);
        db.UserRingItems.AddRange(ringItems);
        await db.SaveChangesAsync();
    }
}
