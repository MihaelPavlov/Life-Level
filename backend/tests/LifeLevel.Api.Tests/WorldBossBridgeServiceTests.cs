using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Infrastructure;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.WorldZone.Application.Ports;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

// Type aliases: 'WorldZone' class name conflicts with the 'LifeLevel.Modules.WorldZone' namespace.
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;
using UserZoneUnlockEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserZoneUnlock;

namespace LifeLevel.Api.Tests;

// ──────────────────────────────────────────────────────────────────────────
// Port stubs (bridge-specific — other files already have noops we reuse).
// ──────────────────────────────────────────────────────────────────────────

file sealed class BridgeXpPort : ICharacterXpPort
{
    public Task<XpAwardResult> AwardXpAsync(Guid u, string s, string e, string d, long xp, CancellationToken ct = default)
        => Task.FromResult(XpAwardResult.None);
}

// Stand-in IServiceProvider for bridge tests that never call
// BossService.GetDamageHistoryAsync — always returns null so the damage-history
// path short-circuits to an empty list.
file sealed class EmptyServiceProvider : IServiceProvider
{
    public static readonly EmptyServiceProvider Instance = new();
    public object? GetService(Type serviceType) => null;
}

file sealed class BridgeCharacterLevelReadPort(DbContext db) : ICharacterLevelReadPort
{
    public async Task<int> GetLevelAsync(Guid userId, CancellationToken ct = default)
        => await db.Set<Character>()
            .Where(c => c.UserId == userId)
            .Select(c => c.Level)
            .FirstOrDefaultAsync(ct);
}

file sealed class BridgeMapNodeCountPort : IMapNodeCountPort
{
    public Task<Dictionary<Guid, int>> GetNodeCountsByZoneIdsAsync(IEnumerable<Guid> zoneIds, CancellationToken ct = default)
        => Task.FromResult(new Dictionary<Guid, int>());
}

file sealed class BridgeMapNodeCompletedCountPort : IMapNodeCompletedCountPort
{
    public Task<Dictionary<Guid, int>> GetCompletedNodeCountsByZoneIdsAsync(Guid userId, IEnumerable<Guid> zoneIds, CancellationToken ct = default)
        => Task.FromResult(new Dictionary<Guid, int>());
}

file sealed class BridgeEventPublisher : IEventPublisher
{
    public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default) where TEvent : IDomainEvent
        => Task.CompletedTask;
}

// ──────────────────────────────────────────────────────────────────────────
// Fixture helpers
// ──────────────────────────────────────────────────────────────────────────

public class WorldBossBridgeServiceTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private static WorldBossBridgeService CreateBridge(AppDbContext db)
        => new WorldBossBridgeService(db, new BossSpawnAdapter(db));

    private static WorldZoneService CreateWorldService(AppDbContext db, WorldBossBridgeService? bridge = null)
        => new WorldZoneService(
            db,
            new BridgeXpPort(),
            new BridgeCharacterLevelReadPort(db),
            new BridgeMapNodeCountPort(),
            new BridgeMapNodeCompletedCountPort(),
            dungeonService: null,
            bossBridge: bridge,
            logger: null);

    /// <summary>
    /// Seed a minimal world with two regions: chapter 1 (Forest) ending in a
    /// boss zone, and chapter 2 (Ocean) with an entry zone linked via a
    /// cross-region edge. Returns everything a test might assert on.
    /// </summary>
    private static async Task<BossFixture> SeedBossWorldAsync(AppDbContext db, string testName)
    {
        var world = new World { Id = Guid.NewGuid(), Name = testName, IsActive = true };
        db.Worlds.Add(world);

        var forestRegion = new Region
        {
            Id = Guid.NewGuid(),
            WorldId = world.Id,
            Name = "Forest",
            Emoji = "🌲",
            Theme = RegionTheme.Forest,
            ChapterIndex = 1,
            LevelRequirement = 1,
            Lore = "Forest lore",
            BossName = "Forest Warden",
        };
        var oceanRegion = new Region
        {
            Id = Guid.NewGuid(),
            WorldId = world.Id,
            Name = "Ocean",
            Emoji = "🌊",
            Theme = RegionTheme.Ocean,
            ChapterIndex = 2,
            LevelRequirement = 1,
            Lore = "Ocean lore",
            BossName = "Tide Sovereign",
        };
        db.Regions.AddRange(forestRegion, oceanRegion);

        var forestEntry = new WorldZoneEntity
        {
            Id = Guid.NewGuid(),
            RegionId = forestRegion.Id,
            Name = "Forest Gate",
            Emoji = "🚪",
            Type = WorldZoneType.Entry,
            Tier = 1,
            IsStartZone = true,
            LevelRequirement = 1,
        };
        var forestBoss = new WorldZoneEntity
        {
            Id = Guid.NewGuid(),
            RegionId = forestRegion.Id,
            Name = "Forest Warden",
            Emoji = "🌳",
            Type = WorldZoneType.Boss,
            Tier = 6,
            IsBoss = true,
            DistanceKm = 5,
            XpReward = 800,
            LevelRequirement = 1,
        };
        var oceanEntry = new WorldZoneEntity
        {
            Id = Guid.NewGuid(),
            RegionId = oceanRegion.Id,
            Name = "Tidepool Landing",
            Emoji = "🏝️",
            Type = WorldZoneType.Entry,
            Tier = 1,
            LevelRequirement = 1,
        };
        db.WorldZones.AddRange(forestEntry, forestBoss, oceanEntry);

        db.WorldZoneEdges.AddRange(
            new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = forestEntry.Id, ToZoneId = forestBoss.Id, DistanceKm = 5, IsBidirectional = false },
            // Cross-region edge boss → next region's entry.
            new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = forestBoss.Id, ToZoneId = oceanEntry.Id, DistanceKm = 0, IsBidirectional = false }
        );

        var userId = Guid.NewGuid();
        db.Users.Add(new User { Id = userId, Username = testName, Email = $"{testName}@test.com", PasswordHash = "x" });
        db.Characters.Add(new Character { Id = Guid.NewGuid(), UserId = userId, Level = 10 });

        await db.SaveChangesAsync();

        return new BossFixture(userId, world, forestRegion, oceanRegion, forestEntry, forestBoss, oceanEntry);
    }

    private record BossFixture(
        Guid UserId,
        World World,
        Region ForestRegion,
        Region OceanRegion,
        WorldZoneEntity ForestEntry,
        WorldZoneEntity ForestBoss,
        WorldZoneEntity OceanEntry);

    // ──────────────────────────────────────────────────────────────────────
    // Test 1: First-time spawn inserts Boss + UserBossState
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task EnsureSpawned_FirstTime_InsertsBossAndUserState()
    {
        var db = CreateDb(nameof(EnsureSpawned_FirstTime_InsertsBossAndUserState));
        var fx = await SeedBossWorldAsync(db, "first_spawn");

        var bridge = CreateBridge(db);
        var bossId = await bridge.EnsureSpawnedAsync(fx.UserId, fx.ForestBoss.Id, CancellationToken.None);

        // Boss row exists with the world-zone link populated.
        var boss = await db.Bosses.FirstOrDefaultAsync(b => b.Id == bossId);
        Assert.NotNull(boss);
        Assert.Equal(fx.ForestBoss.Id, boss!.WorldZoneId);
        Assert.True(boss.SuppressExpiry);
        Assert.Null(boss.NodeId);
        Assert.Equal(fx.ForestBoss.Name, boss.Name);
        Assert.Equal(fx.ForestBoss.Emoji, boss.Icon);
        Assert.Equal(fx.ForestBoss.XpReward, boss.RewardXp);
        // HP formula: 500 * max(chapter=1,1) + 250 * max(tier=6,1) = 500 + 1500 = 2000
        Assert.Equal(500 * 1 + 250 * 6, boss.MaxHp);

        // UserBossState initialized.
        var state = await db.UserBossStates.FirstOrDefaultAsync(s => s.UserId == fx.UserId && s.BossId == bossId);
        Assert.NotNull(state);
        Assert.Equal(0, state!.HpDealt);
        Assert.False(state.IsDefeated);
        Assert.False(state.IsExpired);
        Assert.Null(state.UserMapProgressId); // no local-map progress needed for world-zone bosses
    }

    // ──────────────────────────────────────────────────────────────────────
    // Test 2: Second call is idempotent (same Boss + UserBossState)
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task EnsureSpawned_SecondCall_Idempotent()
    {
        var db = CreateDb(nameof(EnsureSpawned_SecondCall_Idempotent));
        var fx = await SeedBossWorldAsync(db, "idempotent");

        var bridge = CreateBridge(db);
        var firstId = await bridge.EnsureSpawnedAsync(fx.UserId, fx.ForestBoss.Id, CancellationToken.None);
        var secondId = await bridge.EnsureSpawnedAsync(fx.UserId, fx.ForestBoss.Id, CancellationToken.None);

        Assert.Equal(firstId, secondId);
        Assert.Equal(1, await db.Bosses.CountAsync(b => b.WorldZoneId == fx.ForestBoss.Id));
        Assert.Equal(1, await db.UserBossStates.CountAsync(s => s.UserId == fx.UserId && s.BossId == firstId));
    }

    // ──────────────────────────────────────────────────────────────────────
    // Test 3: AddDistanceAsync arrival at a boss zone triggers the bridge
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task AddDistance_ArrivedAtBossZone_TriggersSpawn()
    {
        var db = CreateDb(nameof(AddDistance_ArrivedAtBossZone_TriggersSpawn));
        var fx = await SeedBossWorldAsync(db, "arrival_spawn");

        // Place user at Forest Entry with Forest Boss as the pending destination.
        var edge = await db.WorldZoneEdges.FirstAsync(e => e.FromZoneId == fx.ForestEntry.Id && e.ToZoneId == fx.ForestBoss.Id);
        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = fx.UserId,
            WorldId = fx.World.Id,
            CurrentZoneId = fx.ForestEntry.Id,
            CurrentRegionId = fx.ForestRegion.Id,
            CurrentEdgeId = edge.Id,
            DestinationZoneId = fx.ForestBoss.Id,
            DistanceTraveledOnEdge = 0,
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = fx.UserId, WorldZoneId = fx.ForestEntry.Id, UserWorldProgressId = progress.Id
        });
        await db.SaveChangesAsync();

        var bridge = CreateBridge(db);
        var service = CreateWorldService(db, bridge);

        await service.AddDistanceAsync(fx.UserId, 5);

        var arrivedProgress = await db.UserWorldProgresses.FirstAsync(p => p.UserId == fx.UserId);
        Assert.Equal(fx.ForestBoss.Id, arrivedProgress.CurrentZoneId);

        // Spawn fired on arrival.
        var boss = await db.Bosses.FirstOrDefaultAsync(b => b.WorldZoneId == fx.ForestBoss.Id);
        Assert.NotNull(boss);
        Assert.True(await db.UserBossStates.AnyAsync(s => s.UserId == fx.UserId && s.BossId == boss!.Id));
    }

    // ──────────────────────────────────────────────────────────────────────
    // Test 4: Boss defeat with WorldZoneId → zone completed + region advance
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task BossDefeatedWithWorldZoneId_CompletesZoneAndAdvancesRegion()
    {
        var db = CreateDb(nameof(BossDefeatedWithWorldZoneId_CompletesZoneAndAdvancesRegion));
        var fx = await SeedBossWorldAsync(db, "boss_defeat_advance");

        // Put user at the boss zone.
        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = fx.UserId,
            WorldId = fx.World.Id,
            CurrentZoneId = fx.ForestBoss.Id,
            CurrentRegionId = fx.ForestRegion.Id,
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = fx.UserId, WorldZoneId = fx.ForestEntry.Id, UserWorldProgressId = progress.Id
        });
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = fx.UserId, WorldZoneId = fx.ForestBoss.Id, UserWorldProgressId = progress.Id
        });
        await db.SaveChangesAsync();

        // Spawn the boss via the bridge, then deal lethal damage via BossService.
        var bridge = CreateBridge(db);
        var bossId = await bridge.EnsureSpawnedAsync(fx.UserId, fx.ForestBoss.Id, CancellationToken.None);

        var worldService = CreateWorldService(db, bridge);
        var completionAdapter = new WorldZoneCompletionPortAdapter(worldService);
        var bossService = new BossService(db, new BridgeXpPort(), new BridgeEventPublisher(), EmptyServiceProvider.Instance, completionAdapter);

        var boss = await db.Bosses.FirstAsync(b => b.Id == bossId);
        var result = await bossService.DealDamageAsync(fx.UserId, bossId, boss.MaxHp);

        Assert.True(result.IsDefeated);
        Assert.True(result.JustDefeated);

        // Zone completion fired → user advanced into Ocean's entry zone.
        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == fx.UserId);
        Assert.Equal(fx.OceanEntry.Id, updated.CurrentZoneId);
        Assert.Equal(fx.OceanRegion.Id, updated.CurrentRegionId);

        // Ocean entry is now unlocked too.
        Assert.True(await db.UserZoneUnlocks.AnyAsync(u => u.UserId == fx.UserId && u.WorldZoneId == fx.OceanEntry.Id));

        // Forest boss zone also got an unlock row from CompleteZoneAsync (it
        // was already unlocked before the fight — the re-unlock is a no-op,
        // so we only assert it still exists).
        Assert.True(await db.UserZoneUnlocks.AnyAsync(u => u.UserId == fx.UserId && u.WorldZoneId == fx.ForestBoss.Id));
    }

    // ──────────────────────────────────────────────────────────────────────
    // Test 5: Boss without WorldZoneId (legacy) → no world-zone advance
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task BossDefeatedWithoutWorldZoneId_LegacyPath_NoWorldAdvance()
    {
        var db = CreateDb(nameof(BossDefeatedWithoutWorldZoneId_LegacyPath_NoWorldAdvance));
        var fx = await SeedBossWorldAsync(db, "legacy_boss");

        // Seed a legacy local-map node + boss row with no WorldZoneId link —
        // this simulates the pre-bridge world and must still complete cleanly.
        var mapNode = new LifeLevel.Modules.Map.Domain.Entities.MapNode
        {
            Id = Guid.NewGuid(),
            Name = "Legacy Den",
            Icon = "🏞️",
            Type = LifeLevel.Modules.Map.Domain.Enums.MapNodeType.Boss,
            Region = LifeLevel.Modules.Map.Domain.Enums.MapRegion.ForestOfEndurance,
            LevelRequirement = 1,
        };
        db.MapNodes.Add(mapNode);

        var mapProgress = new LifeLevel.Modules.Map.Domain.Entities.UserMapProgress
        {
            Id = Guid.NewGuid(),
            UserId = fx.UserId,
            CurrentNodeId = mapNode.Id,
            DistanceTraveledOnEdge = 0,
        };
        db.UserMapProgresses.Add(mapProgress);

        var legacyBossId = Guid.NewGuid();
        db.Bosses.Add(new Boss
        {
            Id = legacyBossId,
            NodeId = mapNode.Id,
            Name = "Legacy Titan",
            Icon = "💀",
            MaxHp = 100,
            RewardXp = 500,
            TimerDays = 7,
            IsMini = false,
            WorldZoneId = null,
            SuppressExpiry = false,
        });

        // Already-active UserBossState so DealDamageAsync doesn't complain
        // about unactivated fights.
        db.UserBossStates.Add(new UserBossState
        {
            Id = Guid.NewGuid(),
            UserId = fx.UserId,
            BossId = legacyBossId,
            UserMapProgressId = mapProgress.Id,
            HpDealt = 0,
            IsDefeated = false,
            IsExpired = false,
            StartedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();

        var completionCalls = 0;
        var trackingCompletion = new TrackingWorldZoneCompletionPort(() => completionCalls++);
        var bossService = new BossService(db, new BridgeXpPort(), new BridgeEventPublisher(), EmptyServiceProvider.Instance, trackingCompletion);

        var result = await bossService.DealDamageAsync(fx.UserId, legacyBossId, 100);
        Assert.True(result.IsDefeated);
        Assert.True(result.JustDefeated);

        // No world-zone completion should have been triggered.
        Assert.Equal(0, completionCalls);

        // World progress untouched by the legacy-boss defeat path.
        var worldProgress = await db.UserWorldProgresses.FirstOrDefaultAsync(p => p.UserId == fx.UserId);
        // Either null (no world progress ever created for this user) or, if
        // any earlier test flow created one, it should still be at its seeded
        // zone — never moved to OceanEntry since no cross-region hop fired.
        Assert.True(worldProgress == null || worldProgress.CurrentZoneId != fx.OceanEntry.Id);
    }
}

// Tracks whether CompleteBossZoneAsync was invoked for the legacy-boss regression test.
file sealed class TrackingWorldZoneCompletionPort(Action onCall) : IWorldZoneCompletionPort
{
    public Task CompleteBossZoneAsync(Guid userId, Guid worldZoneId, CancellationToken ct = default)
    {
        onCall();
        return Task.CompletedTask;
    }
}
