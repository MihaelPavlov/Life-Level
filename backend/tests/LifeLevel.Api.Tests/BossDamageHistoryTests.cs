using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

using ActivityEntity = LifeLevel.Modules.Activity.Domain.Entities.Activity;

namespace LifeLevel.Api.Tests;

// ────────────────────────────────────────────────────────────────────────────
// File-local stubs for BossDamageHistoryTests. Kept `file`-scoped so they
// don't collide with look-alike stubs in the rest of the test project.
// ────────────────────────────────────────────────────────────────────────────

file sealed class HistoryNoopXpPort : ICharacterXpPort
{
    public Task<XpAwardResult> AwardXpAsync(Guid u, string s, string e, string d, long xp, CancellationToken ct = default)
        => Task.FromResult(XpAwardResult.None);
}

file sealed class HistoryNoopEvents : IEventPublisher
{
    public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default) where TEvent : IDomainEvent
        => Task.CompletedTask;
}

/// <summary>
/// Reads activities straight from the in-memory DbContext — same behaviour as
/// the real ActivityService implementation, trimmed to what the tests need.
/// </summary>
file sealed class DbActivityHistoryReadPort(DbContext db) : IActivityHistoryReadPort
{
    public async Task<IReadOnlyList<ActivityRecordDto>> ListForUserBetweenAsync(
        Guid userId, DateTime fromUtc, DateTime toUtc, CancellationToken ct = default)
    {
        var characterId = await db.Set<Character>()
            .Where(c => c.UserId == userId)
            .Select(c => (Guid?)c.Id)
            .FirstOrDefaultAsync(ct);
        if (characterId == null) return Array.Empty<ActivityRecordDto>();

        return await db.Set<ActivityEntity>()
            .Where(a => a.CharacterId == characterId
                        && a.LoggedAt >= fromUtc
                        && a.LoggedAt <= toUtc)
            .OrderByDescending(a => a.LoggedAt)
            .Select(a => new ActivityRecordDto(
                a.Id,
                a.Type.ToString(),
                a.DurationMinutes,
                a.DistanceKm,
                a.Calories,
                a.LoggedAt))
            .ToListAsync(ct);
    }
}

public class BossDamageHistoryTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private record BossFixture(Guid UserId, Guid CharacterId, Boss Boss, UserBossState State);

    /// <summary>
    /// Seeds a user + character + boss row + an active UserBossState. The state
    /// has <paramref name="startedAt"/> set and <c>DefeatedAt = null</c> unless
    /// a caller overrides it via the returned handle.
    /// </summary>
    private static async Task<BossFixture> SeedAsync(
        AppDbContext db, string testName, DateTime startedAt, DateTime? defeatedAt = null)
    {
        var userId = Guid.NewGuid();
        var characterId = Guid.NewGuid();

        db.Users.Add(new User
        {
            Id = userId,
            Username = testName,
            Email = $"{testName}@test.com",
            PasswordHash = "x"
        });
        db.Characters.Add(new Character { Id = characterId, UserId = userId, Level = 10 });

        var boss = new Boss
        {
            Id = Guid.NewGuid(),
            Name = "Test Warden",
            Icon = "💀",
            MaxHp = 10_000,
            RewardXp = 500,
            TimerDays = 7,
            IsMini = false,
            WorldZoneId = null,
            NodeId = null,
            SuppressExpiry = true,
        };
        db.Bosses.Add(boss);

        var state = new UserBossState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BossId = boss.Id,
            HpDealt = 0,
            IsDefeated = defeatedAt.HasValue,
            IsExpired = false,
            StartedAt = startedAt,
            DefeatedAt = defeatedAt,
        };
        db.UserBossStates.Add(state);

        await db.SaveChangesAsync();
        return new BossFixture(userId, characterId, boss, state);
    }

    private static BossService CreateService(AppDbContext db)
    {
        var services = new ServiceCollection();
        services.AddSingleton<IActivityHistoryReadPort>(new DbActivityHistoryReadPort(db));
        var provider = services.BuildServiceProvider();
        return new BossService(
            db,
            new HistoryNoopXpPort(),
            new HistoryNoopEvents(),
            provider,
            worldZoneCompletion: null);
    }

    // ──────────────────────────────────────────────────────────────────────
    // Test 1: activities inside the fight window come back with the right
    // damage values computed by CalculateDamageFromActivity.
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetDamageHistory_ActivitiesInWindow_ReturnsCalculatedDamagePerActivity()
    {
        var db = CreateDb(nameof(GetDamageHistory_ActivitiesInWindow_ReturnsCalculatedDamagePerActivity));
        var fx = await SeedAsync(db, "in_window", startedAt: DateTime.UtcNow.AddHours(-2));

        // Three activities at distinct timestamps so order is stable.
        var a1 = new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = fx.CharacterId,
            Type = ActivityType.Running,
            DurationMinutes = 45,
            DistanceKm = 5.0,
            Calories = 350,
            LoggedAt = DateTime.UtcNow.AddMinutes(-60),
        };
        var a2 = new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = fx.CharacterId,
            Type = ActivityType.Gym,
            DurationMinutes = 30,
            DistanceKm = 0,
            Calories = 200,
            LoggedAt = DateTime.UtcNow.AddMinutes(-30),
        };
        var a3 = new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = fx.CharacterId,
            Type = ActivityType.Yoga,
            DurationMinutes = 20,
            DistanceKm = 0,
            Calories = 100,
            LoggedAt = DateTime.UtcNow.AddMinutes(-5),
        };
        db.Activities.AddRange(a1, a2, a3);
        await db.SaveChangesAsync();

        var svc = CreateService(db);
        var history = await svc.GetDamageHistoryAsync(fx.UserId, fx.Boss.Id);

        Assert.Equal(3, history.Count);

        // Port orders newest-first: a3, a2, a1.
        Assert.Equal(a3.Id, history[0].ActivityId);
        Assert.Equal(a2.Id, history[1].ActivityId);
        Assert.Equal(a1.Id, history[2].ActivityId);

        var expected1 = BossService.CalculateDamageFromActivity("Running", 45, 5.0, 350);
        var expected2 = BossService.CalculateDamageFromActivity("Gym", 30, 0, 200);
        var expected3 = BossService.CalculateDamageFromActivity("Yoga", 20, 0, 100);

        Assert.Equal(expected3, history[0].Damage);
        Assert.Equal(expected2, history[1].Damage);
        Assert.Equal(expected1, history[2].Damage);

        Assert.Equal("Yoga", history[0].ActivityType);
        Assert.Equal(20, history[0].DurationMinutes);
        Assert.Equal(0, history[0].DistanceKm);
        Assert.Equal(100, history[0].Calories);
    }

    // ──────────────────────────────────────────────────────────────────────
    // Test 2: activities before state.StartedAt are filtered out.
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetDamageHistory_ActivitiesBeforeWindow_AreExcluded()
    {
        var db = CreateDb(nameof(GetDamageHistory_ActivitiesBeforeWindow_AreExcluded));
        var startedAt = DateTime.UtcNow.AddMinutes(-30);
        var fx = await SeedAsync(db, "before_window", startedAt: startedAt);

        // Before the window.
        db.Activities.Add(new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = fx.CharacterId,
            Type = ActivityType.Running,
            DurationMinutes = 60,
            DistanceKm = 10.0,
            Calories = 600,
            LoggedAt = startedAt.AddMinutes(-5),
        });
        // Inside the window — should be the only one returned.
        var keeper = new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = fx.CharacterId,
            Type = ActivityType.Gym,
            DurationMinutes = 25,
            DistanceKm = 0,
            Calories = 180,
            LoggedAt = startedAt.AddMinutes(5),
        };
        db.Activities.Add(keeper);
        await db.SaveChangesAsync();

        var svc = CreateService(db);
        var history = await svc.GetDamageHistoryAsync(fx.UserId, fx.Boss.Id);

        Assert.Single(history);
        Assert.Equal(keeper.Id, history[0].ActivityId);
    }

    // ──────────────────────────────────────────────────────────────────────
    // Test 3: no UserBossState → InvalidOperationException.
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetDamageHistory_NoUserBossState_Throws()
    {
        var db = CreateDb(nameof(GetDamageHistory_NoUserBossState_Throws));

        // Seed a user + boss but NO UserBossState row.
        var userId = Guid.NewGuid();
        db.Users.Add(new User
        {
            Id = userId,
            Username = "no_state",
            Email = "no_state@test.com",
            PasswordHash = "x"
        });
        db.Characters.Add(new Character { Id = Guid.NewGuid(), UserId = userId, Level = 5 });
        var bossId = Guid.NewGuid();
        db.Bosses.Add(new Boss
        {
            Id = bossId,
            Name = "Untouched",
            Icon = "💀",
            MaxHp = 100,
            RewardXp = 50,
            TimerDays = 7,
        });
        await db.SaveChangesAsync();

        var svc = CreateService(db);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => svc.GetDamageHistoryAsync(userId, bossId));
    }

    // ──────────────────────────────────────────────────────────────────────
    // Test 4: when the fight is already defeated, the window caps at
    // DefeatedAt — activities logged after that point are excluded.
    // ──────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetDamageHistory_AfterDefeat_WindowCapsAtDefeatedAt()
    {
        var db = CreateDb(nameof(GetDamageHistory_AfterDefeat_WindowCapsAtDefeatedAt));
        var startedAt = DateTime.UtcNow.AddHours(-1);
        var defeatedAt = DateTime.UtcNow.AddMinutes(-10);
        var fx = await SeedAsync(db, "after_defeat", startedAt: startedAt, defeatedAt: defeatedAt);

        // Inside the window (before defeat) — included.
        var inside = new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = fx.CharacterId,
            Type = ActivityType.Running,
            DurationMinutes = 40,
            DistanceKm = 5.0,
            Calories = 300,
            LoggedAt = defeatedAt.AddMinutes(-15),
        };
        // After defeat — excluded.
        var after = new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = fx.CharacterId,
            Type = ActivityType.Gym,
            DurationMinutes = 30,
            DistanceKm = 0,
            Calories = 200,
            LoggedAt = DateTime.UtcNow.AddMinutes(-5),
        };
        db.Activities.AddRange(inside, after);
        await db.SaveChangesAsync();

        var svc = CreateService(db);
        var history = await svc.GetDamageHistoryAsync(fx.UserId, fx.Boss.Id);

        Assert.Single(history);
        Assert.Equal(inside.Id, history[0].ActivityId);
        Assert.DoesNotContain(history, h => h.ActivityId == after.Id);
    }
}
