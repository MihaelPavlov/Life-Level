using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Infrastructure;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Api.Tests;

file sealed class DamageAdapterNoopXpPort : ICharacterXpPort
{
    public Task<XpAwardResult> AwardXpAsync(
        Guid userId,
        string source,
        string emoji,
        string description,
        long xp,
        CancellationToken ct = default) => Task.FromResult(XpAwardResult.None);
}

file sealed class DamageAdapterNoopEvents : IEventPublisher
{
    public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
        where TEvent : IDomainEvent => Task.CompletedTask;
}

public class ActivityBossDamageAdapterTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private static ActivityBossDamageAdapter CreateAdapter(AppDbContext db)
    {
        var bossService = new BossService(
            db,
            new DamageAdapterNoopXpPort(),
            new DamageAdapterNoopEvents(),
            new ServiceCollection().BuildServiceProvider());

        return new ActivityBossDamageAdapter(db, bossService);
    }

    [Fact]
    public async Task ApplyAsync_BossStartedAfterActivity_DoesNotDamageOrBackdateFight()
    {
        var db = CreateDb(nameof(ApplyAsync_BossStartedAfterActivity_DoesNotDamageOrBackdateFight));
        var userId = Guid.NewGuid();
        var bossId = Guid.NewGuid();
        var activityLoggedAt = DateTime.UtcNow;
        var bossStartedAt = activityLoggedAt.AddSeconds(2);

        db.Bosses.Add(new Boss
        {
            Id = bossId,
            Name = "Forest Warden",
            Icon = "assets/Bosses/boss_forest_warden.png",
            MaxHp = 1000,
            RewardXp = 500,
            WorldZoneId = Guid.NewGuid(),
            SuppressExpiry = true,
        });
        db.UserBossStates.Add(new UserBossState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BossId = bossId,
            HpDealt = 0,
            StartedAt = bossStartedAt,
        });
        await db.SaveChangesAsync();

        var result = await CreateAdapter(db).ApplyAsync(
            userId, "Running", 45, 5.0, 350, activityLoggedAt);

        var state = await db.UserBossStates.SingleAsync(s => s.BossId == bossId);
        Assert.Empty(result);
        Assert.Equal(0, state.HpDealt);
        Assert.Equal(bossStartedAt, state.StartedAt);
    }

    [Fact]
    public async Task ApplyAsync_BossStartedBeforeActivity_DamagesBoss()
    {
        var db = CreateDb(nameof(ApplyAsync_BossStartedBeforeActivity_DamagesBoss));
        var userId = Guid.NewGuid();
        var bossId = Guid.NewGuid();
        var activityLoggedAt = DateTime.UtcNow;

        db.Bosses.Add(new Boss
        {
            Id = bossId,
            Name = "Forest Warden",
            Icon = "assets/Bosses/boss_forest_warden.png",
            MaxHp = 1000,
            RewardXp = 500,
            WorldZoneId = Guid.NewGuid(),
            SuppressExpiry = true,
        });
        db.UserBossStates.Add(new UserBossState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BossId = bossId,
            HpDealt = 0,
            StartedAt = activityLoggedAt.AddSeconds(-2),
        });
        await db.SaveChangesAsync();

        await CreateAdapter(db).ApplyAsync(
            userId, "Running", 45, 5.0, 350, activityLoggedAt);

        var state = await db.UserBossStates.SingleAsync(s => s.BossId == bossId);
        Assert.Equal(
            BossService.CalculateDamageFromActivity("Running", 45, 5.0, 350),
            state.HpDealt);
    }

    [Fact]
    public async Task ApplyAsync_FirstWorkoutAtBoss_StartsFightAndDealsOneTurn()
    {
        var db = CreateDb(nameof(ApplyAsync_FirstWorkoutAtBoss_StartsFightAndDealsOneTurn));
        var userId = Guid.NewGuid();
        var zoneId = Guid.NewGuid();
        var bossId = Guid.NewGuid();
        var activityId = Guid.NewGuid();
        var at = DateTime.UtcNow;
        db.Bosses.Add(new Boss { Id = bossId, Name = "Forest Warden", Icon = "boss",
            MaxHp = 1000, WorldZoneId = zoneId, SuppressExpiry = true });
        db.UserBossStates.Add(new UserBossState { Id = Guid.NewGuid(), UserId = userId,
            BossId = bossId, StartedAt = null, IsTargeted = false });
        await db.SaveChangesAsync();

        var adapter = CreateAdapter(db);
        var position = new WorldBossPosition(zoneId, at.AddMinutes(-1));
        var first = await adapter.ApplyAsync(userId, activityId, "Running", 30,
            2, 100, at, bossPositionAtStart: position);
        var state = await db.UserBossStates.SingleAsync(s => s.BossId == bossId);
        Assert.Equal(at, state.StartedAt);
        Assert.True(state.IsTargeted);
        Assert.True(first.CombatTurn!.DamageDealt > 0);
        Assert.Single(db.Set<BossCombatTurn>());

        var duplicate = await adapter.ApplyAsync(userId, activityId, "Running", 30,
            2, 100, at, bossPositionAtStart: position);
        Assert.Null(duplicate.CombatTurn);
        Assert.Single(db.Set<BossCombatTurn>());
    }

    [Fact]
    public async Task ApplyAsync_ActiveTargetWinsOverWaitingBoss()
    {
        var db = CreateDb(nameof(ApplyAsync_ActiveTargetWinsOverWaitingBoss));
        var userId = Guid.NewGuid();
        var at = DateTime.UtcNow;
        var activeBossId = Guid.NewGuid();
        var waitingBossId = Guid.NewGuid();
        var currentZoneId = Guid.NewGuid();
        db.Bosses.AddRange(
            new Boss { Id = activeBossId, Name = "Old", Icon = "old", MaxHp = 1000,
                WorldZoneId = Guid.NewGuid(), SuppressExpiry = true },
            new Boss { Id = waitingBossId, Name = "Current", Icon = "current", MaxHp = 1000,
                WorldZoneId = currentZoneId, SuppressExpiry = true });
        db.UserBossStates.AddRange(
            new UserBossState { Id = Guid.NewGuid(), UserId = userId,
                BossId = activeBossId, StartedAt = at.AddMinutes(-2), IsTargeted = true },
            new UserBossState { Id = Guid.NewGuid(), UserId = userId,
                BossId = waitingBossId });
        await db.SaveChangesAsync();

        var result = await CreateAdapter(db).ApplyAsync(userId, Guid.NewGuid(),
            "Running", 30, 2, 100, at,
            bossPositionAtStart: new WorldBossPosition(currentZoneId, at.AddMinutes(-1)));
        Assert.Equal(activeBossId, result.CombatTurn!.BossId);
        Assert.Null((await db.UserBossStates.SingleAsync(s => s.BossId == waitingBossId)).StartedAt);

        // A late import from before the existing fight cannot switch targets.
        var older = await CreateAdapter(db).ApplyAsync(userId, Guid.NewGuid(),
            "Running", 30, 2, 100, at.AddMinutes(-3),
            bossPositionAtStart: new WorldBossPosition(currentZoneId, at.AddMinutes(-4)));
        Assert.Null(older.CombatTurn);
        Assert.Null((await db.UserBossStates.SingleAsync(s => s.BossId == waitingBossId)).StartedAt);
    }

    [Fact]
    public async Task ApplyAsync_ArrivalWorkoutOrOldImport_DoesNotStartBoss()
    {
        var db = CreateDb(nameof(ApplyAsync_ArrivalWorkoutOrOldImport_DoesNotStartBoss));
        var userId = Guid.NewGuid();
        var zoneId = Guid.NewGuid();
        var bossId = Guid.NewGuid();
        var at = DateTime.UtcNow;
        db.Bosses.Add(new Boss { Id = bossId, Name = "Forest Warden", Icon = "boss",
            MaxHp = 1000, WorldZoneId = zoneId, SuppressExpiry = true });
        db.UserBossStates.Add(new UserBossState { Id = Guid.NewGuid(), UserId = userId, BossId = bossId });
        await db.SaveChangesAsync();
        var adapter = CreateAdapter(db);
        Assert.Null((await adapter.ApplyAsync(userId, Guid.NewGuid(), "Running", 30,
            2, 100, at)).CombatTurn);
        Assert.Null((await adapter.ApplyAsync(userId, Guid.NewGuid(), "Running", 30,
            2, 100, at, bossPositionAtStart: new WorldBossPosition(zoneId, at.AddMinutes(1)))).CombatTurn);
        Assert.Null((await adapter.ApplyAsync(userId, Guid.NewGuid(), "Running", 30,
            2, 100, at, bossPositionAtStart: new WorldBossPosition(zoneId, at.AddMinutes(-1)),
            allowAutomaticStart: false)).CombatTurn);
        Assert.Null((await db.UserBossStates.SingleAsync()).StartedAt);
    }

    [Fact]
    public async Task ApplyAsync_ResolvedBossCannotStartAgain()
    {
        var db = CreateDb(nameof(ApplyAsync_ResolvedBossCannotStartAgain));
        var userId = Guid.NewGuid();
        var zoneId = Guid.NewGuid();
        var at = DateTime.UtcNow;
        db.Bosses.Add(new Boss { Id = Guid.NewGuid(), Name = "Defeated", Icon = "boss",
            MaxHp = 1000, WorldZoneId = zoneId, SuppressExpiry = true });
        var bossId = db.Bosses.Local.Single().Id;
        db.UserBossStates.Add(new UserBossState { Id = Guid.NewGuid(), UserId = userId,
            BossId = bossId, IsDefeated = true });
        await db.SaveChangesAsync();

        var result = await CreateAdapter(db).ApplyAsync(userId, Guid.NewGuid(),
            "Running", 30, 2, 100, at,
            bossPositionAtStart: new WorldBossPosition(zoneId, at.AddMinutes(-1)));
        Assert.Null(result.CombatTurn);
        Assert.Null((await db.UserBossStates.SingleAsync()).StartedAt);
    }
}
