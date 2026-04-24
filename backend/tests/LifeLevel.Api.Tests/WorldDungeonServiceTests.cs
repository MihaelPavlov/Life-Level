using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;
using UserZoneUnlockEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserZoneUnlock;

namespace LifeLevel.Api.Tests;

file sealed class DungeonXpPort : ICharacterXpPort
{
    public List<(string Source, string Emoji, long Xp, string Description)> Awards { get; } = [];

    public Task<XpAwardResult> AwardXpAsync(
        Guid userId, string source, string emoji, string description, long xp,
        CancellationToken ct = default)
    {
        Awards.Add((source, emoji, xp, description));
        return Task.FromResult(XpAwardResult.None);
    }
}

public class WorldDungeonServiceTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private record DungeonSetup(
        Guid UserId, World World, Region Region,
        WorldZoneEntity EntryZone, WorldZoneEntity DungeonZone,
        WorldZoneEntity AfterZone,
        List<WorldZoneDungeonFloor> Floors,
        UserWorldProgressEntity Progress);

    /// <summary>
    /// Seeds a region with Entry → Dungeon → After linear layout. Three floors
    /// on the dungeon: Run 3km (F1), Gym 30min (F2), Yoga 15min (F3). The user
    /// is placed standing on the dungeon zone.
    /// </summary>
    private static async Task<DungeonSetup> SeedDungeonAsync(AppDbContext db, string dbName, int bonusXp = 510)
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
            BossName = "Boss",
        };
        db.Regions.Add(region);

        var userId = Guid.NewGuid();
        db.Users.Add(new User { Id = userId, Username = dbName, Email = $"{dbName}@t.com", PasswordHash = "x" });
        db.Characters.Add(new Character { Id = Guid.NewGuid(), UserId = userId, Level = 10 });

        var entry = new WorldZoneEntity
        {
            Id = Guid.NewGuid(), RegionId = region.Id,
            Name = "Entry", Emoji = "🚪",
            Type = WorldZoneType.Entry, Tier = 1, IsStartZone = true,
        };
        var dungeon = new WorldZoneEntity
        {
            Id = Guid.NewGuid(), RegionId = region.Id,
            Name = "Sunken Ruins", Emoji = "🏚️",
            Type = WorldZoneType.Dungeon, Tier = 2,
            DistanceKm = 4.0,
            DungeonBonusXp = bonusXp,
        };
        var after = new WorldZoneEntity
        {
            Id = Guid.NewGuid(), RegionId = region.Id,
            Name = "After", Emoji = "🍂",
            Type = WorldZoneType.Standard, Tier = 3,
            DistanceKm = 3.0, XpReward = 300,
        };
        db.WorldZones.AddRange(entry, dungeon, after);

        db.WorldZoneEdges.AddRange(
            new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = entry.Id,   ToZoneId = dungeon.Id, DistanceKm = 4.0, IsBidirectional = true },
            new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = dungeon.Id, ToZoneId = after.Id,   DistanceKm = 3.0, IsBidirectional = true });

        var floors = new List<WorldZoneDungeonFloor>
        {
            new()
            {
                Id = Guid.NewGuid(), WorldZoneId = dungeon.Id, Ordinal = 1,
                Name = "Running trial", Emoji = "🏃",
                ActivityType = ActivityType.Running,
                TargetKind = DungeonFloorTargetKind.DistanceKm, TargetValue = 3.0,
            },
            new()
            {
                Id = Guid.NewGuid(), WorldZoneId = dungeon.Id, Ordinal = 2,
                Name = "Strength trial", Emoji = "🏋️",
                ActivityType = ActivityType.Gym,
                TargetKind = DungeonFloorTargetKind.DurationMinutes, TargetValue = 30,
            },
            new()
            {
                Id = Guid.NewGuid(), WorldZoneId = dungeon.Id, Ordinal = 3,
                Name = "Balance trial", Emoji = "🧘",
                ActivityType = ActivityType.Yoga,
                TargetKind = DungeonFloorTargetKind.DurationMinutes, TargetValue = 15,
            },
        };
        db.WorldZoneDungeonFloors.AddRange(floors);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = world.Id,
            CurrentZoneId = dungeon.Id,
            CurrentRegionId = region.Id,
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.AddRange(
            new UserZoneUnlockEntity { UserId = userId, WorldZoneId = entry.Id, UserWorldProgressId = progress.Id },
            new UserZoneUnlockEntity { UserId = userId, WorldZoneId = dungeon.Id, UserWorldProgressId = progress.Id });

        await db.SaveChangesAsync();
        return new DungeonSetup(userId, world, region, entry, dungeon, after, floors, progress);
    }

    // ────────────────────────────────────────────────────────────────────────
    // Enter + state
    // ────────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task EnterDungeon_FirstTime_CreatesRunWithFloor1Active()
    {
        var db = CreateDb(nameof(EnterDungeon_FirstTime_CreatesRunWithFloor1Active));
        var setup = await SeedDungeonAsync(db, "dungeon_first");

        var service = new WorldDungeonService(db, new DungeonXpPort());
        await service.EnterAsync(setup.UserId, setup.DungeonZone.Id);

        var run = await db.UserWorldDungeonStates
            .FirstAsync(s => s.UserId == setup.UserId && s.WorldZoneId == setup.DungeonZone.Id);
        Assert.Equal(DungeonRunStatus.InProgress, run.Status);
        Assert.Equal(1, run.CurrentFloorOrdinal);
        Assert.NotNull(run.StartedAt);

        var floorStates = await db.UserWorldDungeonFloorStates
            .Where(s => s.UserId == setup.UserId)
            .ToListAsync();
        Assert.Equal(3, floorStates.Count);
        var floor1State = floorStates.Single(s => s.FloorId == setup.Floors[0].Id);
        var floor2State = floorStates.Single(s => s.FloorId == setup.Floors[1].Id);
        var floor3State = floorStates.Single(s => s.FloorId == setup.Floors[2].Id);
        Assert.Equal(DungeonFloorStatus.Active, floor1State.Status);
        Assert.Equal(DungeonFloorStatus.Locked, floor2State.Status);
        Assert.Equal(DungeonFloorStatus.Locked, floor3State.Status);
    }

    [Fact]
    public async Task EnterDungeon_NotAtZone_Throws()
    {
        var db = CreateDb(nameof(EnterDungeon_NotAtZone_Throws));
        var setup = await SeedDungeonAsync(db, "dungeon_not_at_zone");

        // Move user off the dungeon zone.
        setup.Progress.CurrentZoneId = setup.EntryZone.Id;
        await db.SaveChangesAsync();

        var service = new WorldDungeonService(db, new DungeonXpPort());
        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.EnterAsync(setup.UserId, setup.DungeonZone.Id));

        var run = await db.UserWorldDungeonStates
            .FirstOrDefaultAsync(s => s.UserId == setup.UserId && s.WorldZoneId == setup.DungeonZone.Id);
        Assert.Null(run);
    }

    [Fact]
    public async Task EnterDungeon_AlreadyInProgress_NoOpIdempotent()
    {
        var db = CreateDb(nameof(EnterDungeon_AlreadyInProgress_NoOpIdempotent));
        var setup = await SeedDungeonAsync(db, "dungeon_idempotent");

        var service = new WorldDungeonService(db, new DungeonXpPort());
        await service.EnterAsync(setup.UserId, setup.DungeonZone.Id);
        // Second call should not throw and should not create duplicate state.
        await service.EnterAsync(setup.UserId, setup.DungeonZone.Id);

        var runs = await db.UserWorldDungeonStates
            .Where(s => s.UserId == setup.UserId && s.WorldZoneId == setup.DungeonZone.Id)
            .ToListAsync();
        Assert.Single(runs);

        var floorStates = await db.UserWorldDungeonFloorStates
            .Where(s => s.UserId == setup.UserId)
            .ToListAsync();
        Assert.Equal(3, floorStates.Count); // NOT 6 — no dupes
    }

    [Fact]
    public async Task GetDungeonState_ReturnsFloorsInOrdinalOrder()
    {
        var db = CreateDb(nameof(GetDungeonState_ReturnsFloorsInOrdinalOrder));
        var setup = await SeedDungeonAsync(db, "dungeon_get_state", bonusXp: 510);

        var service = new WorldDungeonService(db, new DungeonXpPort());
        await service.EnterAsync(setup.UserId, setup.DungeonZone.Id);

        var state = await service.GetStateAsync(setup.UserId, setup.DungeonZone.Id);
        Assert.NotNull(state);
        Assert.Equal(setup.DungeonZone.Id, state!.ZoneId);
        Assert.Equal("inProgress", state.Status);
        Assert.Equal(1, state.CurrentFloorOrdinal);
        Assert.Equal(510, state.BonusXp);

        Assert.Equal(3, state.Floors.Count);
        Assert.Equal(1, state.Floors[0].Ordinal);
        Assert.Equal(2, state.Floors[1].Ordinal);
        Assert.Equal(3, state.Floors[2].Ordinal);

        Assert.Equal("active", state.Floors[0].Status);
        Assert.Equal("locked", state.Floors[1].Status);
        Assert.Equal("locked", state.Floors[2].Status);
    }

    // ────────────────────────────────────────────────────────────────────────
    // Activity credit (Phase 3)
    // ────────────────────────────────────────────────────────────────────────

    [Fact]
    public async Task CreditActivity_MatchingType_AccumulatesProgress()
    {
        var db = CreateDb(nameof(CreditActivity_MatchingType_AccumulatesProgress));
        var setup = await SeedDungeonAsync(db, "credit_accumulate");

        var service = new WorldDungeonService(db, new DungeonXpPort());
        await service.EnterAsync(setup.UserId, setup.DungeonZone.Id);

        // Log a 1.5-km run — Floor 1 target is 3 km, so this accumulates but
        // doesn't clear.
        var result = await service.CreditActivityAsync(
            setup.UserId, ActivityType.Running, distanceKm: 1.5, durationMinutes: 15);
        Assert.Null(result); // no clear

        var floor1State = await db.UserWorldDungeonFloorStates
            .FirstAsync(s => s.UserId == setup.UserId && s.FloorId == setup.Floors[0].Id);
        Assert.Equal(1.5, floor1State.ProgressValue, precision: 2);
        Assert.Equal(DungeonFloorStatus.Active, floor1State.Status);
    }

    [Fact]
    public async Task CreditActivity_ReachesTarget_AdvancesFloor()
    {
        var db = CreateDb(nameof(CreditActivity_ReachesTarget_AdvancesFloor));
        var setup = await SeedDungeonAsync(db, "credit_advance");

        var service = new WorldDungeonService(db, new DungeonXpPort());
        await service.EnterAsync(setup.UserId, setup.DungeonZone.Id);

        var result = await service.CreditActivityAsync(
            setup.UserId, ActivityType.Running, distanceKm: 3.0, durationMinutes: 30);
        Assert.NotNull(result);
        Assert.Equal(1, result!.ClearedFloorOrdinal);
        Assert.Equal(3, result.TotalFloors);
        Assert.False(result.RunCompleted);
        Assert.Equal(0, result.BonusXpAwarded);

        var run = await db.UserWorldDungeonStates
            .FirstAsync(s => s.UserId == setup.UserId && s.WorldZoneId == setup.DungeonZone.Id);
        Assert.Equal(2, run.CurrentFloorOrdinal);
        Assert.Equal(DungeonRunStatus.InProgress, run.Status);

        var floor1State = await db.UserWorldDungeonFloorStates
            .FirstAsync(s => s.UserId == setup.UserId && s.FloorId == setup.Floors[0].Id);
        var floor2State = await db.UserWorldDungeonFloorStates
            .FirstAsync(s => s.UserId == setup.UserId && s.FloorId == setup.Floors[1].Id);
        Assert.Equal(DungeonFloorStatus.Completed, floor1State.Status);
        Assert.Equal(DungeonFloorStatus.Active, floor2State.Status);
    }

    [Fact]
    public async Task CreditActivity_NonMatchingType_NoOp()
    {
        var db = CreateDb(nameof(CreditActivity_NonMatchingType_NoOp));
        var setup = await SeedDungeonAsync(db, "credit_wrong_type");

        var service = new WorldDungeonService(db, new DungeonXpPort());
        await service.EnterAsync(setup.UserId, setup.DungeonZone.Id);

        // Floor 1 wants Running; log Cycling instead.
        var result = await service.CreditActivityAsync(
            setup.UserId, ActivityType.Cycling, distanceKm: 5.0, durationMinutes: 20);
        Assert.Null(result);

        var floor1State = await db.UserWorldDungeonFloorStates
            .FirstAsync(s => s.UserId == setup.UserId && s.FloorId == setup.Floors[0].Id);
        Assert.Equal(0.0, floor1State.ProgressValue);
        Assert.Equal(DungeonFloorStatus.Active, floor1State.Status);
    }

    [Fact]
    public async Task CreditActivity_FinalFloor_AwardsBonusXp()
    {
        var db = CreateDb(nameof(CreditActivity_FinalFloor_AwardsBonusXp));
        var setup = await SeedDungeonAsync(db, "credit_final", bonusXp: 510);

        var xp = new DungeonXpPort();
        var service = new WorldDungeonService(db, xp);
        await service.EnterAsync(setup.UserId, setup.DungeonZone.Id);

        // Clear floor 1 (Running 3km).
        await service.CreditActivityAsync(setup.UserId, ActivityType.Running, 3.0, 30);
        // Clear floor 2 (Gym 30 min).
        await service.CreditActivityAsync(setup.UserId, ActivityType.Gym, 0, 30);
        // Clear floor 3 (Yoga 15 min) — run completes.
        var finalResult = await service.CreditActivityAsync(setup.UserId, ActivityType.Yoga, 0, 15);

        Assert.NotNull(finalResult);
        Assert.True(finalResult!.RunCompleted);
        Assert.Equal(3, finalResult.ClearedFloorOrdinal);
        Assert.Equal(510, finalResult.BonusXpAwarded);

        var run = await db.UserWorldDungeonStates
            .FirstAsync(s => s.UserId == setup.UserId && s.WorldZoneId == setup.DungeonZone.Id);
        Assert.Equal(DungeonRunStatus.Completed, run.Status);
        Assert.NotNull(run.FinishedAt);

        // Bonus XP award was emitted on final clear.
        Assert.Single(xp.Awards);
        var award = xp.Awards[0];
        Assert.Equal("DungeonClear", award.Source);
        Assert.Equal(510, award.Xp);
    }

    // ────────────────────────────────────────────────────────────────────────
    // Forfeit wiring (Phase 3)
    // ────────────────────────────────────────────────────────────────────────

    private static WorldZoneService CreateWorldZoneService(AppDbContext db, WorldDungeonService dungeonService)
        => new(
            db,
            new DungeonXpPort(),
            new DungeonDbCharacterLevelReadPort(db),
            new DungeonEmptyMapNodeCountPort(),
            new DungeonEmptyMapNodeCompletedCountPort(),
            dungeonService);

    [Fact]
    public async Task SetDestination_AbandonsInProgressDungeon_ForfeitsFloors()
    {
        var db = CreateDb(nameof(SetDestination_AbandonsInProgressDungeon_ForfeitsFloors));
        var setup = await SeedDungeonAsync(db, "forfeit_setdest");

        var dungeonService = new WorldDungeonService(db, new DungeonXpPort());
        await dungeonService.EnterAsync(setup.UserId, setup.DungeonZone.Id);

        // Clear floor 1 so we can see it stays Completed while floors 2 & 3 are forfeited.
        await dungeonService.CreditActivityAsync(setup.UserId, ActivityType.Running, 3.0, 30);

        // Now user tries to leave the dungeon for the "After" zone.
        var worldService = CreateWorldZoneService(db, dungeonService);
        var result = await worldService.SetDestinationAsync(setup.UserId, setup.AfterZone.Id);

        Assert.Equal(2, result.ForfeitedFloors);

        var run = await db.UserWorldDungeonStates
            .FirstAsync(s => s.UserId == setup.UserId && s.WorldZoneId == setup.DungeonZone.Id);
        Assert.Equal(DungeonRunStatus.Abandoned, run.Status);
        Assert.NotNull(run.FinishedAt);

        var floorStates = await db.UserWorldDungeonFloorStates
            .Where(s => s.UserId == setup.UserId)
            .ToListAsync();
        Assert.Equal(DungeonFloorStatus.Completed, floorStates.Single(s => s.FloorId == setup.Floors[0].Id).Status);
        Assert.Equal(DungeonFloorStatus.Forfeited, floorStates.Single(s => s.FloorId == setup.Floors[1].Id).Status);
        Assert.Equal(DungeonFloorStatus.Forfeited, floorStates.Single(s => s.FloorId == setup.Floors[2].Id).Status);
    }

    [Fact]
    public async Task SetDestination_NoActiveDungeon_NormalFlow()
    {
        var db = CreateDb(nameof(SetDestination_NoActiveDungeon_NormalFlow));
        var setup = await SeedDungeonAsync(db, "forfeit_no_dungeon");

        // User is not on the dungeon zone — move them to the entry zone first.
        setup.Progress.CurrentZoneId = setup.EntryZone.Id;
        await db.SaveChangesAsync();

        var dungeonService = new WorldDungeonService(db, new DungeonXpPort());
        var worldService = CreateWorldZoneService(db, dungeonService);
        var result = await worldService.SetDestinationAsync(setup.UserId, setup.DungeonZone.Id);

        Assert.Equal(0, result.ForfeitedFloors);

        // No run created — we only set a destination.
        var runs = await db.UserWorldDungeonStates
            .Where(s => s.UserId == setup.UserId)
            .ToListAsync();
        Assert.Empty(runs);
    }
}

// ────────────────────────────────────────────────────────────────────────────
// File-private port stubs (duplicating WorldZoneServiceTests stubs on purpose —
// both tests file-private the same shapes).
// ────────────────────────────────────────────────────────────────────────────

file sealed class DungeonDbCharacterLevelReadPort(DbContext db) : ICharacterLevelReadPort
{
    public async Task<int> GetLevelAsync(Guid userId, CancellationToken ct = default)
        => await db.Set<Character>()
            .Where(c => c.UserId == userId)
            .Select(c => c.Level)
            .FirstOrDefaultAsync(ct);
}

file sealed class DungeonEmptyMapNodeCountPort : IMapNodeCountPort
{
    public Task<Dictionary<Guid, int>> GetNodeCountsByZoneIdsAsync(IEnumerable<Guid> zoneIds, CancellationToken ct = default)
        => Task.FromResult(new Dictionary<Guid, int>());
}

file sealed class DungeonEmptyMapNodeCompletedCountPort : IMapNodeCompletedCountPort
{
    public Task<Dictionary<Guid, int>> GetCompletedNodeCountsByZoneIdsAsync(Guid userId, IEnumerable<Guid> zoneIds, CancellationToken ct = default)
        => Task.FromResult(new Dictionary<Guid, int>());
}
