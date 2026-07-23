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
            Icon = "assets/Bosses/boss_forest_warden.svg",
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
            Icon = "assets/Bosses/boss_forest_warden.svg",
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
}
