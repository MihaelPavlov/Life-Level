using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

// Type alias: 'WorldZone' class name conflicts with the 'LifeLevel.Modules.WorldZone' namespace
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;
using UserZoneUnlockEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserZoneUnlock;

namespace LifeLevel.Api.Tests;

file sealed class NoOpCharacterXpPort : ICharacterXpPort
{
    public Task<XpAwardResult> AwardXpAsync(Guid u, string s, string e, string d, long xp, CancellationToken ct = default)
        => Task.FromResult(XpAwardResult.None);
}

file sealed class DbCharacterLevelReadPort(DbContext db) : ICharacterLevelReadPort
{
    public async Task<int> GetLevelAsync(Guid userId, CancellationToken ct = default)
        => await db.Set<Character>()
            .Where(c => c.UserId == userId)
            .Select(c => c.Level)
            .FirstOrDefaultAsync(ct);
}

file sealed class EmptyMapNodeCountPort : IMapNodeCountPort
{
    public Task<Dictionary<Guid, int>> GetNodeCountsByZoneIdsAsync(IEnumerable<Guid> zoneIds, CancellationToken ct = default)
        => Task.FromResult(new Dictionary<Guid, int>());
}

file sealed class EmptyMapNodeCompletedCountPort : IMapNodeCompletedCountPort
{
    public Task<Dictionary<Guid, int>> GetCompletedNodeCountsByZoneIdsAsync(Guid userId, IEnumerable<Guid> zoneIds, CancellationToken ct = default)
        => Task.FromResult(new Dictionary<Guid, int>());
}

public class WorldZoneServiceTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private static WorldZoneService CreateService(AppDbContext db)
        => new WorldZoneService(
            db,
            new NoOpCharacterXpPort(),
            new DbCharacterLevelReadPort(db),
            new EmptyMapNodeCountPort(),
            new EmptyMapNodeCompletedCountPort());

    // Helper: build a minimal (World, Region, Zone) triple. Region is required
    // on every zone so every test has to seed one at minimum.
    private static (World World, Region Region) SeedWorld(AppDbContext db, string worldName = "Test World", int levelReq = 1)
    {
        var world = new World { Id = Guid.NewGuid(), Name = worldName, IsActive = true };
        db.Worlds.Add(world);
        var region = new Region
        {
            Id = Guid.NewGuid(),
            WorldId = world.Id,
            Name = $"{worldName} Region",
            Emoji = "🌲",
            Theme = RegionTheme.Forest,
            ChapterIndex = 1,
            LevelRequirement = levelReq,
            Lore = "Test lore",
            BossName = "Test Boss",
        };
        db.Regions.Add(region);
        return (world, region);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 1: GetFullWorldAsync returns all zones with correct user state
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetFullWorldAsync_ReturnsAllZonesWithUserState()
    {
        var db = CreateDb(nameof(GetFullWorldAsync_ReturnsAllZonesWithUserState));
        var (world, region) = SeedWorld(db);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test", Email = "test@test.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 5 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 1", IsStartZone = true, LevelRequirement = 1, Type = WorldZoneType.Entry };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 2", LevelRequirement = 3, Type = WorldZoneType.Standard };
        db.WorldZones.AddRange(zone1, zone2);

        var edge = new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = zone1.Id, ToZoneId = zone2.Id, DistanceKm = 10 };
        db.WorldZoneEdges.Add(edge);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = zone1.Id,
            CurrentRegionId = region.Id,
            DistanceTraveledOnEdge = 0
        };
        db.UserWorldProgresses.Add(progress);

        var unlock = new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id,
            UnlockedAt = DateTime.UtcNow
        };
        db.UserZoneUnlocks.Add(unlock);

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.GetFullWorldAsync(userId);

        Assert.Equal(2, result.Zones.Count);
        Assert.Equal(5, result.CharacterLevel);

        var z1Dto = result.Zones.Single(z => z.Id == zone1.Id);
        Assert.True(z1Dto.UserState!.IsUnlocked);
        Assert.True(z1Dto.UserState.IsCurrentZone);
        Assert.False(z1Dto.UserState.IsDestination);
        Assert.True(z1Dto.UserState.IsLevelMet);

        var z2Dto = result.Zones.Single(z => z.Id == zone2.Id);
        Assert.False(z2Dto.UserState!.IsUnlocked);
        Assert.False(z2Dto.UserState.IsCurrentZone);
        Assert.True(z2Dto.UserState.IsLevelMet); // level 5 >= level req 3

        Assert.Single(result.Edges);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 2: GetFullWorldAsync initializes progress when missing
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetFullWorldAsync_InitializesProgressIfMissing()
    {
        var db = CreateDb(nameof(GetFullWorldAsync_InitializesProgressIfMissing));
        var (world, region) = SeedWorld(db, "Start World");

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test2", Email = "test2@test.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 1 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var startZone = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Start Zone", IsStartZone = true, LevelRequirement = 1, Type = WorldZoneType.Entry };
        db.WorldZones.Add(startZone);

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.GetFullWorldAsync(userId);

        var progress = await db.UserWorldProgresses.FirstOrDefaultAsync(p => p.UserId == userId);
        Assert.NotNull(progress);
        Assert.Equal(startZone.Id, progress.CurrentZoneId);

        var unlock = await db.UserZoneUnlocks.FirstOrDefaultAsync(u => u.UserId == userId && u.WorldZoneId == startZone.Id);
        Assert.NotNull(unlock);

        var startZoneDto = result.Zones.Single(z => z.Id == startZone.Id);
        Assert.True(startZoneDto.UserState!.IsUnlocked);
        Assert.True(startZoneDto.UserState.IsCurrentZone);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 3: SetDestinationAsync sets edge and destination correctly
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task SetDestinationAsync_SetsEdgeAndDestination()
    {
        var db = CreateDb(nameof(SetDestinationAsync_SetsEdgeAndDestination));
        var (world, region) = SeedWorld(db);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test3", Email = "test3@test.com", PasswordHash = "x" };
        db.Users.Add(user);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 1", IsStartZone = true };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 2" };
        db.WorldZones.AddRange(zone1, zone2);

        var edge = new WorldZoneEdge
        {
            Id = Guid.NewGuid(),
            FromZoneId = zone1.Id,
            ToZoneId = zone2.Id,
            DistanceKm = 5,
            IsBidirectional = true
        };
        db.WorldZoneEdges.Add(edge);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = zone1.Id
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        await service.SetDestinationAsync(userId, zone2.Id);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == userId);
        Assert.Equal(zone2.Id, updated.DestinationZoneId);
        Assert.Equal(edge.Id, updated.CurrentEdgeId);
        Assert.Equal(0, updated.DistanceTraveledOnEdge);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 4: SetDestinationAsync throws when destination is not adjacent
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task SetDestinationAsync_ThrowsIfNotAdjacent()
    {
        var db = CreateDb(nameof(SetDestinationAsync_ThrowsIfNotAdjacent));
        var (world, region) = SeedWorld(db);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test4", Email = "test4@test.com", PasswordHash = "x" };
        db.Users.Add(user);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 1", IsStartZone = true };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 2" };
        db.WorldZones.AddRange(zone1, zone2);
        // No edge between zone1 and zone2

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = zone1.Id
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.SetDestinationAsync(userId, zone2.Id));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 5: AddDistanceAsync arrives at destination, unlocks zone
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task AddDistanceAsync_ArrivesAtDestination()
    {
        var db = CreateDb(nameof(AddDistanceAsync_ArrivesAtDestination));
        var (world, region) = SeedWorld(db);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test5", Email = "test5@test.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 1 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 1", IsStartZone = true };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 2", XpReward = 0 };
        db.WorldZones.AddRange(zone1, zone2);

        var edge = new WorldZoneEdge
        {
            Id = Guid.NewGuid(),
            FromZoneId = zone1.Id,
            ToZoneId = zone2.Id,
            DistanceKm = 5,
            IsBidirectional = true
        };
        db.WorldZoneEdges.Add(edge);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = zone1.Id,
            CurrentEdgeId = edge.Id,
            DestinationZoneId = zone2.Id,
            DistanceTraveledOnEdge = 0
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        await service.AddDistanceAsync(userId, 5);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == userId);
        Assert.Equal(zone2.Id, updated.CurrentZoneId);
        Assert.Null(updated.CurrentEdgeId);
        Assert.Null(updated.DestinationZoneId);
        Assert.Equal(0, updated.DistanceTraveledOnEdge);

        var zone2Unlock = await db.UserZoneUnlocks
            .FirstOrDefaultAsync(u => u.UserId == userId && u.WorldZoneId == zone2.Id);
        Assert.NotNull(zone2Unlock);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 7: CompleteZoneAsync unlocks zone and awards XP
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task CompleteZoneAsync_UnlocksZoneAndAwardsXp()
    {
        var db = CreateDb(nameof(CompleteZoneAsync_UnlocksZoneAndAwardsXp));
        var (world, region) = SeedWorld(db);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test7", Email = "test7@test.com", PasswordHash = "x" };
        db.Users.Add(user);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 1", IsStartZone = true };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 2", Emoji = "🏔️", XpReward = 200 };
        db.WorldZones.AddRange(zone1, zone2);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = zone1.Id
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.CompleteZoneAsync(userId, zone2.Id);

        Assert.Equal("Zone 2", result.ZoneName);
        Assert.Equal(200, result.XpAwarded);
        Assert.False(result.AlreadyCompleted);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == userId);
        Assert.Equal(zone2.Id, updated.CurrentZoneId);

        var unlock = await db.UserZoneUnlocks
            .FirstOrDefaultAsync(u => u.UserId == userId && u.WorldZoneId == zone2.Id);
        Assert.NotNull(unlock);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 8: CompleteZoneAsync returns AlreadyCompleted for re-completion
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task CompleteZoneAsync_AlreadyCompleted_NoDoubleXp()
    {
        var db = CreateDb(nameof(CompleteZoneAsync_AlreadyCompleted_NoDoubleXp));
        var (world, region) = SeedWorld(db);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test8", Email = "test8@test.com", PasswordHash = "x" };
        db.Users.Add(user);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 1", IsStartZone = true, XpReward = 100 };
        db.WorldZones.Add(zone1);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = zone1.Id
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.CompleteZoneAsync(userId, zone1.Id);

        Assert.True(result.AlreadyCompleted);
        Assert.Equal(0, result.XpAwarded); // no double XP
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 9: AddDistanceAsync is a silent no-op when no destination is set
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task AddDistanceAsync_NoDestination_SilentNoOp()
    {
        var db = CreateDb(nameof(AddDistanceAsync_NoDestination_SilentNoOp));
        var (world, region) = SeedWorld(db);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test9", Email = "test9@test.com", PasswordHash = "x" };
        db.Users.Add(user);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 1", IsStartZone = true };
        db.WorldZones.Add(zone1);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = zone1.Id
            // No CurrentEdgeId or DestinationZoneId
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);

        await service.AddDistanceAsync(userId, 3);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == userId);
        Assert.Equal(zone1.Id, updated.CurrentZoneId);
        Assert.Null(updated.CurrentEdgeId);
        Assert.Null(updated.DestinationZoneId);
        Assert.Equal(0, updated.DistanceTraveledOnEdge);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 10: AddDistanceAsync partial travel does not unlock destination
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task AddDistanceAsync_PartialTravel_DoesNotArrive()
    {
        var db = CreateDb(nameof(AddDistanceAsync_PartialTravel_DoesNotArrive));
        var (world, region) = SeedWorld(db);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test10", Email = "test10@test.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 1 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 1", IsStartZone = true };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "Zone 2" };
        db.WorldZones.AddRange(zone1, zone2);

        var edge = new WorldZoneEdge
        {
            Id = Guid.NewGuid(),
            FromZoneId = zone1.Id,
            ToZoneId = zone2.Id,
            DistanceKm = 10,
            IsBidirectional = true
        };
        db.WorldZoneEdges.Add(edge);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = zone1.Id,
            CurrentEdgeId = edge.Id,
            DestinationZoneId = zone2.Id,
            DistanceTraveledOnEdge = 0
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        await service.AddDistanceAsync(userId, 4); // only 4 of 10 km

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == userId);
        Assert.Equal(zone1.Id, updated.CurrentZoneId);
        Assert.Equal(edge.Id, updated.CurrentEdgeId);
        Assert.Equal(zone2.Id, updated.DestinationZoneId);
        Assert.Equal(4, updated.DistanceTraveledOnEdge);

        var zone2Unlock = await db.UserZoneUnlocks
            .FirstOrDefaultAsync(u => u.UserId == userId && u.WorldZoneId == zone2.Id);
        Assert.Null(zone2Unlock);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 11: GetFullWorldAsync returns empty when no active world exists
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetFullWorldAsync_NoActiveWorld_ReturnsEmpty()
    {
        var db = CreateDb(nameof(GetFullWorldAsync_NoActiveWorld_ReturnsEmpty));

        var service = CreateService(db);
        var result = await service.GetFullWorldAsync(Guid.NewGuid());

        Assert.Empty(result.Zones);
        Assert.Empty(result.Edges);
        Assert.Equal(0, result.CharacterLevel);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Helper: seed a fork topology (crossroads → [branchA, branchB] → rejoin).
    // Returns the ids so individual tests can reason about them.
    // ──────────────────────────────────────────────────────────────────────────
    private record ForkSetup(
        Guid UserId,
        World World,
        Region Region,
        WorldZoneEntity Crossroads,
        WorldZoneEntity BranchA,
        WorldZoneEntity BranchB,
        WorldZoneEntity Rejoin,
        UserWorldProgressEntity Progress);

    private static async Task<ForkSetup> SeedForkAsync(AppDbContext db, string testName)
    {
        var (world, region) = SeedWorld(db, testName);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = testName, Email = $"{testName}@test.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 10 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var crossroads = new WorldZoneEntity
        {
            Id = Guid.NewGuid(),
            RegionId = region.Id,
            Name = "Fork",
            Emoji = "🔀",
            Type = WorldZoneType.Crossroads,
            Tier = 1,
            LevelRequirement = 1,
        };
        var branchA = new WorldZoneEntity
        {
            Id = Guid.NewGuid(),
            RegionId = region.Id,
            Name = "Branch A",
            Emoji = "🌾",
            Type = WorldZoneType.Standard,
            Tier = 2,
            DistanceKm = 5,
            XpReward = 400,
            LevelRequirement = 1,
            BranchOfId = null, // set below once ids are stable
        };
        var branchB = new WorldZoneEntity
        {
            Id = Guid.NewGuid(),
            RegionId = region.Id,
            Name = "Branch B",
            Emoji = "⛰️",
            Type = WorldZoneType.Standard,
            Tier = 2,
            DistanceKm = 3,
            XpReward = 600,
            LevelRequirement = 1,
            BranchOfId = null,
        };
        branchA.BranchOfId = crossroads.Id;
        branchB.BranchOfId = crossroads.Id;

        var rejoin = new WorldZoneEntity
        {
            Id = Guid.NewGuid(),
            RegionId = region.Id,
            Name = "Rejoin",
            Emoji = "🍂",
            Type = WorldZoneType.Standard,
            Tier = 3,
            DistanceKm = 4,
            XpReward = 500,
            LevelRequirement = 1,
        };

        db.WorldZones.AddRange(crossroads, branchA, branchB, rejoin);

        // Edges: crossroads → branchA, crossroads → branchB, each branch → rejoin.
        db.WorldZoneEdges.AddRange(
            new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = crossroads.Id, ToZoneId = branchA.Id, DistanceKm = branchA.DistanceKm, IsBidirectional = false },
            new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = crossroads.Id, ToZoneId = branchB.Id, DistanceKm = branchB.DistanceKm, IsBidirectional = false },
            new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = branchA.Id,    ToZoneId = rejoin.Id,  DistanceKm = 0,                  IsBidirectional = false },
            new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = branchB.Id,    ToZoneId = rejoin.Id,  DistanceKm = 0,                  IsBidirectional = false }
        );

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = crossroads.Id,
            CurrentRegionId = region.Id,
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = crossroads.Id,
            UserWorldProgressId = progress.Id,
        });

        await db.SaveChangesAsync();
        return new ForkSetup(userId, world, region, crossroads, branchA, branchB, rejoin, progress);
    }

    private static MapReadService CreateMapReadService(AppDbContext db)
        => new MapReadService(db, new DbCharacterLevelReadPort(db), new StaticUsernameReadPort("Tester"), new EmptyBossDefeatReadPort());

    // ──────────────────────────────────────────────────────────────────────────
    // Test 12: SetDestination on a branch with no prior choice records a
    // UserPathChoice row.
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task SetDestination_Branch_FirstChoice_CreatesPathChoice()
    {
        var db = CreateDb(nameof(SetDestination_Branch_FirstChoice_CreatesPathChoice));
        var setup = await SeedForkAsync(db, "fork_first_choice");

        var service = CreateService(db);
        await service.SetDestinationAsync(setup.UserId, setup.BranchA.Id);

        var choices = await db.UserPathChoices
            .Where(c => c.UserId == setup.UserId)
            .ToListAsync();

        Assert.Single(choices);
        Assert.Equal(setup.Crossroads.Id, choices[0].CrossroadsZoneId);
        Assert.Equal(setup.BranchA.Id, choices[0].ChosenBranchZoneId);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == setup.UserId);
        Assert.Equal(setup.BranchA.Id, updated.DestinationZoneId);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 13: Attempting to pick the sibling after a choice exists throws
    // PathAlreadyChosenException.
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task SetDestination_Branch_OtherPath_ThrowsPathAlreadyChosen()
    {
        var db = CreateDb(nameof(SetDestination_Branch_OtherPath_ThrowsPathAlreadyChosen));
        var setup = await SeedForkAsync(db, "fork_already_chosen");

        // Pre-seed: user has committed to branch A.
        db.UserPathChoices.Add(new UserPathChoice
        {
            Id = Guid.NewGuid(),
            UserId = setup.UserId,
            CrossroadsZoneId = setup.Crossroads.Id,
            ChosenBranchZoneId = setup.BranchA.Id,
            ChosenAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);

        await Assert.ThrowsAsync<PathAlreadyChosenException>(
            () => service.SetDestinationAsync(setup.UserId, setup.BranchB.Id));

        // Destination must remain unchanged from the pre-test state.
        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == setup.UserId);
        Assert.Null(updated.DestinationZoneId);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 14: After a path choice, GetRegionDetail reports the sibling branch
    // as status "locked".
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetRegionDetail_AfterChoice_SiblingBranchLocked()
    {
        var db = CreateDb(nameof(GetRegionDetail_AfterChoice_SiblingBranchLocked));
        var setup = await SeedForkAsync(db, "fork_detail_locked");

        // User commits to branch A.
        db.UserPathChoices.Add(new UserPathChoice
        {
            Id = Guid.NewGuid(),
            UserId = setup.UserId,
            CrossroadsZoneId = setup.Crossroads.Id,
            ChosenBranchZoneId = setup.BranchA.Id,
            ChosenAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var mapRead = CreateMapReadService(db);
        var detail = await mapRead.GetRegionDetailAsync(setup.UserId, setup.Region.Id);

        Assert.NotNull(detail);
        var branchBNode = detail!.Nodes.Single(n => n.Id == setup.BranchB.Id);
        Assert.Equal("locked", branchBNode.Status);

        var branchANode = detail.Nodes.Single(n => n.Id == setup.BranchA.Id);
        Assert.NotEqual("locked", branchANode.Status); // chosen branch remains open

        Assert.Contains(detail.PathChoices, pc =>
            pc.CrossroadsZoneId == setup.Crossroads.Id && pc.ChosenZoneId == setup.BranchA.Id);

        // BranchOf wiring round-trips on the DTO.
        Assert.Equal(setup.Crossroads.Id, branchANode.BranchOf);
        Assert.Equal(setup.Crossroads.Id, branchBNode.BranchOf);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Banking-km drain tests (regression: SetDestination with pending km used
    // to overflow the edge length without firing arrival; AddDistance used to
    // drop excess on final arrival).
    // ──────────────────────────────────────────────────────────────────────────

    /// Helper: seed a minimal A→B world with the given edge length and a user
    /// already at A (no destination, no current edge) holding `pendingKm`
    /// banked. Returns the A and B zone ids.
    private async Task<(Guid A, Guid B, Guid EdgeId)> SeedSimpleAToBAsync(
        AppDbContext db, string testName, double edgeKm, double pendingKm)
    {
        var (world, region) = SeedWorld(db);
        var userId = TestUserId;

        var user = new User { Id = userId, Username = testName, Email = $"{testName}@t.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 1 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var a = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "A", IsStartZone = true };
        var b = new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = region.Id, Name = "B", XpReward = 0 };
        db.WorldZones.AddRange(a, b);

        var edge = new WorldZoneEdge
        {
            Id = Guid.NewGuid(),
            FromZoneId = a.Id,
            ToZoneId = b.Id,
            DistanceKm = edgeKm,
            IsBidirectional = true,
        };
        db.WorldZoneEdges.Add(edge);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = a.Id,
            DistanceTraveledOnEdge = 0,
            PendingDistanceKm = pendingKm,
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = a.Id,
            UserWorldProgressId = progress.Id,
        });
        await db.SaveChangesAsync();

        return (a.Id, b.Id, edge.Id);
    }

    private static readonly Guid TestUserId = Guid.NewGuid();

    [Fact]
    public async Task SetDestination_WithPendingExceedingEdge_ArrivesAndBanksOverflow()
    {
        var db = CreateDb(nameof(SetDestination_WithPendingExceedingEdge_ArrivesAndBanksOverflow));
        var (_, b, _) = await SeedSimpleAToBAsync(db, "bank_overflow", edgeKm: 4.2, pendingKm: 5.0);

        var service = CreateService(db);
        await service.SetDestinationAsync(TestUserId, b);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == TestUserId);
        Assert.Equal(b, updated.CurrentZoneId);
        Assert.Null(updated.CurrentEdgeId);
        Assert.Null(updated.DestinationZoneId);
        Assert.Equal(0, updated.DistanceTraveledOnEdge);
        Assert.Equal(0.8, updated.PendingDistanceKm, precision: 5);
    }

    [Fact]
    public async Task SetDestination_WithPendingMatchingEdge_ArrivesWithZeroBank()
    {
        var db = CreateDb(nameof(SetDestination_WithPendingMatchingEdge_ArrivesWithZeroBank));
        var (_, b, _) = await SeedSimpleAToBAsync(db, "bank_exact", edgeKm: 4.2, pendingKm: 4.2);

        var service = CreateService(db);
        await service.SetDestinationAsync(TestUserId, b);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == TestUserId);
        Assert.Equal(b, updated.CurrentZoneId);
        Assert.Null(updated.CurrentEdgeId);
        Assert.Null(updated.DestinationZoneId);
        Assert.Equal(0, updated.PendingDistanceKm, precision: 5);
        Assert.Equal(0, updated.DistanceTraveledOnEdge);
    }

    [Fact]
    public async Task SetDestination_WithPendingShorterThanEdge_PartiallyTravels()
    {
        var db = CreateDb(nameof(SetDestination_WithPendingShorterThanEdge_PartiallyTravels));
        var (a, b, edgeId) = await SeedSimpleAToBAsync(db, "bank_partial", edgeKm: 4.2, pendingKm: 2.5);

        var service = CreateService(db);
        await service.SetDestinationAsync(TestUserId, b);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == TestUserId);
        Assert.Equal(a, updated.CurrentZoneId);
        Assert.Equal(b, updated.DestinationZoneId);
        Assert.Equal(edgeId, updated.CurrentEdgeId);
        Assert.Equal(2.5, updated.DistanceTraveledOnEdge, precision: 5);
        Assert.Equal(0, updated.PendingDistanceKm, precision: 5);
    }

    [Fact]
    public async Task AddDistance_WithExcessOnFinalDestination_BanksOverflow()
    {
        var db = CreateDb(nameof(AddDistance_WithExcessOnFinalDestination_BanksOverflow));
        var (_, b, edgeId) = await SeedSimpleAToBAsync(db, "bank_excess_arrival", edgeKm: 4.2, pendingKm: 0);

        // Start the user mid-edge with a destination set, so the next
        // AddDistance call exercises the final-arrival branch.
        var progress = await db.UserWorldProgresses.FirstAsync(p => p.UserId == TestUserId);
        progress.CurrentEdgeId = edgeId;
        progress.DestinationZoneId = b;
        progress.DistanceTraveledOnEdge = 4.0;
        await db.SaveChangesAsync();

        var service = CreateService(db);
        // 4.0 already on edge + 1.0 added = 5.0 total; edge is 4.2 → 0.8
        // overflow that should land back in PendingDistanceKm.
        await service.AddDistanceAsync(TestUserId, 1.0);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == TestUserId);
        Assert.Equal(b, updated.CurrentZoneId);
        Assert.Null(updated.CurrentEdgeId);
        Assert.Null(updated.DestinationZoneId);
        Assert.Equal(0.8, updated.PendingDistanceKm, precision: 5);
    }
}

// Supporting stub: MapReadService needs a username read port. Tests don't care
// about the actual username so return a constant.
file sealed class StaticUsernameReadPort(string name) : IUserReadPort
{
    public Task<string?> GetUsernameAsync(Guid userId, CancellationToken ct = default)
        => Task.FromResult<string?>(name);
}

// Supporting stub: MapReadService now needs boss-defeat state. Tests in this
// file don't exercise boss completion — empty set is fine.
file sealed class EmptyBossDefeatReadPort : IBossDefeatReadPort
{
    public Task<HashSet<Guid>> GetDefeatedWorldZoneIdsAsync(Guid userId, CancellationToken ct = default)
        => Task.FromResult(new HashSet<Guid>());
}
