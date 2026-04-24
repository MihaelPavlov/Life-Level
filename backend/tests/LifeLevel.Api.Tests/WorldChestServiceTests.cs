using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;
using UserZoneUnlockEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserZoneUnlock;

namespace LifeLevel.Api.Tests;

// Captures every XP award so tests can assert on source/amount.
file sealed class CapturingCharacterXpPort : ICharacterXpPort
{
    public record AwardCall(Guid UserId, string Source, string Emoji, string Description, long Xp);

    public List<AwardCall> Awards { get; } = [];

    public Task<XpAwardResult> AwardXpAsync(
        Guid userId, string source, string emoji, string description, long xp,
        CancellationToken ct = default)
    {
        Awards.Add(new AwardCall(userId, source, emoji, description, xp));
        return Task.FromResult(XpAwardResult.None);
    }
}

file sealed class ChestDbCharacterLevelReadPort(DbContext db) : ICharacterLevelReadPort
{
    public async Task<int> GetLevelAsync(Guid userId, CancellationToken ct = default)
        => await db.Set<Character>()
            .Where(c => c.UserId == userId)
            .Select(c => c.Level)
            .FirstOrDefaultAsync(ct);
}

file sealed class ChestStaticUsernameReadPort(string name) : IUserReadPort
{
    public Task<string?> GetUsernameAsync(Guid userId, CancellationToken ct = default)
        => Task.FromResult<string?>(name);
}

file sealed class ChestEmptyBossDefeatReadPort : IBossDefeatReadPort
{
    public Task<HashSet<Guid>> GetDefeatedWorldZoneIdsAsync(Guid userId, CancellationToken ct = default)
        => Task.FromResult(new HashSet<Guid>());
}

public class WorldChestServiceTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    // Seed a minimal world + region + chest zone + user standing on the chest.
    private record ChestSetup(
        Guid UserId, World World, Region Region,
        WorldZoneEntity ChestZone, WorldZoneEntity EntryZone,
        UserWorldProgressEntity Progress);

    private static async Task<ChestSetup> SeedChestAsync(AppDbContext db, string dbName, int rewardXp = 250)
    {
        var world = new World { Id = Guid.NewGuid(), Name = dbName, IsActive = true };
        db.Worlds.Add(world);

        var region = new Region
        {
            Id = Guid.NewGuid(),
            WorldId = world.Id,
            Name = $"{dbName} Region",
            Emoji = "🌲",
            Theme = RegionTheme.Forest,
            ChapterIndex = 1,
            LevelRequirement = 1,
            Lore = "Test lore",
            BossName = "Test Boss",
        };
        db.Regions.Add(region);

        var userId = Guid.NewGuid();
        db.Users.Add(new User
        {
            Id = userId, Username = dbName, Email = $"{dbName}@t.com", PasswordHash = "x",
        });
        db.Characters.Add(new Character { Id = Guid.NewGuid(), UserId = userId, Level = 3 });

        var entryZone = new WorldZoneEntity
        {
            Id = Guid.NewGuid(), RegionId = region.Id,
            Name = "Entry", Emoji = "🚪",
            Type = WorldZoneType.Entry, Tier = 1,
            IsStartZone = true, LevelRequirement = 1,
        };
        var chestZone = new WorldZoneEntity
        {
            Id = Guid.NewGuid(), RegionId = region.Id,
            Name = "Whispering Shrine", Emoji = "🗝️",
            Type = WorldZoneType.Chest, Tier = 2,
            LevelRequirement = 1,
            DistanceKm = 2.0,
            ChestRewardXp = rewardXp,
            ChestRewardDescription = "A weathered chest.",
        };
        db.WorldZones.AddRange(entryZone, chestZone);

        // User is standing on the chest zone already (test precondition).
        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = chestZone.Id,
            CurrentRegionId = region.Id,
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId, WorldZoneId = entryZone.Id, UserWorldProgressId = progress.Id,
        });
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId, WorldZoneId = chestZone.Id, UserWorldProgressId = progress.Id,
        });

        await db.SaveChangesAsync();
        return new ChestSetup(userId, world, region, chestZone, entryZone, progress);
    }

    [Fact]
    public async Task OpenChest_FirstTime_AwardsXpAndMarksOpened()
    {
        var db = CreateDb(nameof(OpenChest_FirstTime_AwardsXpAndMarksOpened));
        var setup = await SeedChestAsync(db, "chest_first", rewardXp: 250);

        var xp = new CapturingCharacterXpPort();
        var service = new WorldChestService(db, xp);

        var result = await service.OpenAsync(setup.UserId, setup.ChestZone.Id);

        Assert.Equal(setup.ChestZone.Id, result.ZoneId);
        Assert.Equal("Whispering Shrine", result.ZoneName);
        Assert.Equal(250, result.Xp);

        // Chest state row exists.
        var state = await db.UserWorldChestStates
            .FirstOrDefaultAsync(s => s.UserId == setup.UserId && s.WorldZoneId == setup.ChestZone.Id);
        Assert.NotNull(state);

        // XP was awarded via the port.
        Assert.Single(xp.Awards);
        var award = xp.Awards[0];
        Assert.Equal("ChestReward", award.Source);
        Assert.Equal("🎁", award.Emoji);
        Assert.Equal(250, award.Xp);
    }

    [Fact]
    public async Task OpenChest_AlreadyOpened_Throws()
    {
        var db = CreateDb(nameof(OpenChest_AlreadyOpened_Throws));
        var setup = await SeedChestAsync(db, "chest_reopen");

        // Pre-seed: chest has already been opened.
        db.UserWorldChestStates.Add(new UserWorldChestState
        {
            Id = Guid.NewGuid(),
            UserId = setup.UserId,
            WorldZoneId = setup.ChestZone.Id,
            OpenedAt = DateTime.UtcNow.AddDays(-1),
        });
        await db.SaveChangesAsync();

        var xp = new CapturingCharacterXpPort();
        var service = new WorldChestService(db, xp);

        await Assert.ThrowsAsync<ChestAlreadyOpenedException>(
            () => service.OpenAsync(setup.UserId, setup.ChestZone.Id));

        // No additional XP was awarded.
        Assert.Empty(xp.Awards);
    }

    [Fact]
    public async Task OpenChest_NotAtZone_Throws()
    {
        var db = CreateDb(nameof(OpenChest_NotAtZone_Throws));
        var setup = await SeedChestAsync(db, "chest_not_at_zone");

        // Move the user off the chest zone.
        setup.Progress.CurrentZoneId = setup.EntryZone.Id;
        await db.SaveChangesAsync();

        var xp = new CapturingCharacterXpPort();
        var service = new WorldChestService(db, xp);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.OpenAsync(setup.UserId, setup.ChestZone.Id));

        var state = await db.UserWorldChestStates
            .FirstOrDefaultAsync(s => s.UserId == setup.UserId && s.WorldZoneId == setup.ChestZone.Id);
        Assert.Null(state);
    }

    [Fact]
    public async Task GetRegionDetail_ChestOpened_ReturnsIsOpenedTrue()
    {
        var db = CreateDb(nameof(GetRegionDetail_ChestOpened_ReturnsIsOpenedTrue));
        var setup = await SeedChestAsync(db, "chest_region_detail", rewardXp: 320);

        // Open it by inserting the state row directly — we want to assert on
        // the read-side DTO, not exercise the service again.
        db.UserWorldChestStates.Add(new UserWorldChestState
        {
            Id = Guid.NewGuid(),
            UserId = setup.UserId,
            WorldZoneId = setup.ChestZone.Id,
            OpenedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var mapRead = new MapReadService(db, new ChestDbCharacterLevelReadPort(db), new ChestStaticUsernameReadPort("Tester"), new ChestEmptyBossDefeatReadPort());
        var detail = await mapRead.GetRegionDetailAsync(setup.UserId, setup.Region.Id);

        Assert.NotNull(detail);
        var chestNode = detail!.Nodes.Single(n => n.Id == setup.ChestZone.Id);
        Assert.True(chestNode.IsChest);
        Assert.Equal(320, chestNode.ChestRewardXp);
        Assert.True(chestNode.ChestIsOpened);

        // Entry zone should not be flagged as a chest.
        var entryNode = detail.Nodes.Single(n => n.Id == setup.EntryZone.Id);
        Assert.False(entryNode.IsChest);
        Assert.Null(entryNode.ChestRewardXp);
        Assert.Null(entryNode.ChestIsOpened);
    }
}
