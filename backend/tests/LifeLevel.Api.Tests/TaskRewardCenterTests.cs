using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Quest.Application.UseCases;
using LifeLevel.Modules.Quest.Domain.Entities;
using LifeLevel.Modules.Quest.Domain.Data;
using LifeLevel.Modules.Quest.Domain.Enums;
using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class TaskRewardCenterTests
{
    [Fact]
    public async Task GetRewardPeriodAsync_AssignsFiveDailyTasks_WithExpectedRewardMix()
    {
        await using var db = CreateDb();
        db.Quests.AddRange(Enumerable.Range(1, 5).Select(index => new Quest
        {
            Id = Guid.NewGuid(),
            Title = $"Daily task {index}",
            Description = "Complete a workout.",
            Type = QuestType.Daily,
            Category = QuestCategory.Workouts,
            GroupKey = $"daily:test-{index}",
            TargetValue = 1,
            TargetUnit = "workout",
            IsActive = true,
            SortOrder = index,
        }));
        await db.SaveChangesAsync();

        var period = await CreateService(db).GetRewardPeriodAsync(Guid.NewGuid(), QuestType.Daily);

        Assert.Equal(5, period.Tasks.Count);
        Assert.All(period.Tasks, task => Assert.Equal(20, task.RewardPoints));
        Assert.Equal(4, period.Tasks.Count(task => task.RewardCoins == 35));
        Assert.Single(period.Tasks, task => task.RewardCrystals == 1);
        Assert.Equal([20, 40, 60, 80, 100], period.Milestones.Select(m => m.Threshold));
        Assert.Equal(100, period.PointsMaximum);
        Assert.Equal(DateTime.UtcNow.Date.AddDays(1), period.ResetAtUtc);
    }

    [Fact]
    public async Task CompletingDailyTasks_RequiresClaim_ThenGrantsAllRewardsAndPoints()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        db.Quests.AddRange(Enumerable.Range(1, 5).Select(index => new Quest
        {
            Id = Guid.NewGuid(),
            Title = $"Daily task {index}",
            Description = "Complete a workout.",
            Type = QuestType.Daily,
            Category = QuestCategory.Workouts,
            GroupKey = $"daily:test-{index}",
            TargetValue = 1,
            TargetUnit = "workout",
            IsActive = true,
            SortOrder = index,
        }));
        await db.SaveChangesAsync();
        var currency = new CapturingCurrencyPort();
        var service = CreateService(db, currency);
        await service.GetRewardPeriodAsync(userId, QuestType.Daily);

        await service.UpdateProgressFromActivityAsync(userId, ActivityType.Running, 10, 1, 50);
        var beforeClaim = await service.GetRewardPeriodAsync(userId, QuestType.Daily);

        Assert.Equal(0, beforeClaim.PointsEarned);
        Assert.Equal(0, currency.Coins);
        Assert.Equal(0, currency.Crystals);
        Assert.All(beforeClaim.Tasks, task => Assert.False(task.RewardClaimed));

        var claim = await service.ClaimAvailableTaskRewardsAsync(userId, QuestType.Daily);

        Assert.Equal(5, claim.TasksClaimed);
        Assert.Equal(140, claim.Coins);
        Assert.Equal(1, claim.Crystals);
        Assert.Equal(100, claim.UpdatedPeriod.PointsEarned);
        Assert.Equal(140, currency.Coins);
        Assert.Equal(1, currency.Crystals);
        Assert.All(claim.UpdatedPeriod.Milestones, milestone => Assert.True(milestone.IsUnlocked));
        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.ClaimAvailableTaskRewardsAsync(userId, QuestType.Daily));
    }

    [Fact]
    public async Task ClaimAvailableDailyMilestones_GrantsEveryUnlockedRewardOnce()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        db.Quests.AddRange(Enumerable.Range(1, 5).Select(index => new Quest
        {
            Id = Guid.NewGuid(),
            Title = $"Daily task {index}",
            Description = "Complete a workout.",
            Type = QuestType.Daily,
            Category = QuestCategory.Workouts,
            GroupKey = $"daily:test-{index}",
            TargetValue = 1,
            TargetUnit = "workout",
            IsActive = true,
            SortOrder = index,
        }));
        await db.SaveChangesAsync();

        var currency = new CapturingCurrencyPort();
        var xp = new CapturingXpPort();
        var shields = new CapturingShieldPort();
        var service = CreateService(db, currency, xp, shields);
        await service.GetRewardPeriodAsync(userId, QuestType.Daily);
        await service.UpdateProgressFromActivityAsync(userId, ActivityType.Running, 10, 1, 50);
        await service.ClaimAvailableTaskRewardsAsync(userId, QuestType.Daily);

        var claimed = await service.ClaimAvailableMilestonesAsync(userId, QuestType.Daily);

        Assert.Equal([20, 40, 60, 80, 100], claimed.Select(result => result.Threshold));
        Assert.Equal(240, currency.Coins); // 140 task rewards + 100 milestone rewards
        Assert.Equal(2, currency.Crystals); // 1 task reward + 1 milestone reward
        Assert.Equal(200, xp.TotalXp);
        Assert.Equal(1, shields.Added);
        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.ClaimAvailableMilestonesAsync(userId, QuestType.Daily));
    }

    [Fact]
    public async Task SingleActivityTask_KeepsBestAttempt_InsteadOfAccumulating()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        db.Quests.Add(new Quest
        {
            Id = Guid.NewGuid(), Title = "Focused Half Hour",
            Description = "Complete one workout lasting 30 minutes.",
            Type = QuestType.Daily, Category = QuestCategory.Duration,
            ProgressMode = QuestProgressMode.SingleActivity,
            DifficultyTier = QuestDifficultyTier.Standard,
            GroupKey = "daily:any-duration-single", TargetValue = 30,
            TargetUnit = "minutes", IsActive = true,
        });
        await db.SaveChangesAsync();
        var service = CreateService(db);
        await service.GetRewardPeriodAsync(userId, QuestType.Daily);

        await service.UpdateProgressFromActivityAsync(userId, ActivityType.Running, 20, 0, 0);
        await service.UpdateProgressFromActivityAsync(userId, ActivityType.Walking, 15, 0, 0);

        var task = Assert.Single((await service.GetRewardPeriodAsync(userId, QuestType.Daily)).Tasks);
        Assert.Equal(20, task.CurrentValue);
        Assert.False(task.IsCompleted);
    }

    [Fact]
    public async Task GameEvent_CompletesEligibleTask_AndLeavesRewardClaimable()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        db.Quests.Add(new Quest
        {
            Id = Guid.NewGuid(), Title = "Pathfinder", Description = "Complete 1 zone.",
            Type = QuestType.Weekly, Category = QuestCategory.ZonesCompleted,
            GroupKey = "weekly:zones", TargetValue = 1, TargetUnit = "zone", IsActive = true,
        });
        await db.SaveChangesAsync();
        var currency = new CapturingCurrencyPort();
        var service = CreateService(db, currency, eligibility: new AllowAllEligibilityPort());
        await service.GetRewardPeriodAsync(userId, QuestType.Weekly);

        await service.UpdateProgressFromGameEventAsync(userId, QuestCategory.ZonesCompleted);

        var task = Assert.Single((await service.GetRewardPeriodAsync(userId, QuestType.Weekly)).Tasks);
        Assert.True(task.IsCompleted);
        Assert.False(task.RewardClaimed);
        Assert.Equal(0, currency.Crystals);
        Assert.Equal(20, task.RewardPoints);
    }

    [Fact]
    public async Task SeedCatalog_AssignsFiveDailyAndTenWeekly_WithGameCaps()
    {
        await using var db = CreateDb();
        db.Quests.AddRange(QuestSeedData.All.Select(q => new Quest
        {
            Id = q.Id, Title = q.Title, Description = q.Description, Type = q.Type,
            Category = q.Category, ProgressMode = q.ProgressMode,
            DifficultyTier = q.DifficultyTier, GroupKey = q.GroupKey,
            RequiredActivity = q.RequiredActivity, TargetValue = q.TargetValue,
            TargetUnit = q.TargetUnit, RewardXp = q.RewardXp,
            SortOrder = q.SortOrder, IsActive = q.IsActive,
        }));
        await db.SaveChangesAsync();
        var service = CreateService(db, eligibility: new AllowAllEligibilityPort(),
            history: new BroadActivityHistoryPort());
        var userId = Guid.NewGuid();

        var daily = await service.GetRewardPeriodAsync(userId, QuestType.Daily);
        var weekly = await service.GetRewardPeriodAsync(userId, QuestType.Weekly);

        Assert.Equal(5, daily.Tasks.Count);
        Assert.Equal(10, weekly.Tasks.Count);
        Assert.True(daily.Tasks.Count(t => IsGameCategory(t.Category)) <= 1);
        Assert.True(weekly.Tasks.Count(t => IsGameCategory(t.Category)) <= 2);
    }

    private static bool IsGameCategory(string category) => category is
        nameof(QuestCategory.ZonesCompleted) or nameof(QuestCategory.ChestsOpened) or
        nameof(QuestCategory.BossContributions) or nameof(QuestCategory.BossesDefeated) or
        nameof(QuestCategory.GuildRaidContributions) or nameof(QuestCategory.GuildRaidsWon) or
        nameof(QuestCategory.RegionsCompleted);

    private static AppDbContext CreateDb() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static QuestService CreateService(
        AppDbContext db,
        IRewardCurrencyPort? currency = null,
        ICharacterXpPort? xp = null,
        IStreakShieldPort? shields = null,
        ITaskEligibilityReadPort? eligibility = null,
        IActivityHistoryReadPort? history = null) =>
        new(db, xp ?? new StubXpPort(), new NoopEventPublisher(), new NoopItemGrantPort(),
            rewardCurrency: currency, streakShield: shields, taskEligibility: eligibility,
            activityHistory: history);

    private sealed class AllowAllEligibilityPort : ITaskEligibilityReadPort
    {
        public Task<TaskEligibilitySnapshot> GetAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(new TaskEligibilitySnapshot(true, 10, true, true, true));
    }

    private sealed class BroadActivityHistoryPort : IActivityHistoryReadPort
    {
        public Task<IReadOnlyList<ActivityRecordDto>> ListForUserBetweenAsync(
            Guid userId, DateTime fromUtc, DateTime toUtc, CancellationToken ct = default)
        {
            var types = Enum.GetNames<ActivityType>();
            IReadOnlyList<ActivityRecordDto> rows = types.SelectMany((type, i) => new[]
            {
                new ActivityRecordDto(Guid.NewGuid(), type, 45, 8, 400, DateTime.UtcNow.AddDays(-i - 1)),
                new ActivityRecordDto(Guid.NewGuid(), type, 60, 12, 600, DateTime.UtcNow.AddDays(-i - 8)),
            }).ToList();
            return Task.FromResult(rows);
        }
    }

    private sealed class CapturingCurrencyPort : IRewardCurrencyPort
    {
        public int Coins { get; private set; }
        public int Crystals { get; private set; }
        public Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default)
        {
            Coins += amount;
            return Task.CompletedTask;
        }
        public Task AddCrystalsAsync(Guid userId, int amount, CancellationToken ct = default)
        {
            Crystals += amount;
            return Task.CompletedTask;
        }
    }

    private sealed class StubXpPort : ICharacterXpPort
    {
        public Task<XpAwardResult> AwardXpAsync(Guid userId, string source, string sourceEmoji,
            string description, long xp, CancellationToken ct = default) =>
            Task.FromResult(new XpAwardResult(false, 1, 1));
    }

    private sealed class CapturingXpPort : ICharacterXpPort
    {
        public long TotalXp { get; private set; }

        public Task<XpAwardResult> AwardXpAsync(Guid userId, string source, string sourceEmoji,
            string description, long xp, CancellationToken ct = default)
        {
            TotalXp += xp;
            return Task.FromResult(new XpAwardResult(false, 1, 1));
        }
    }

    private sealed class CapturingShieldPort : IStreakShieldPort
    {
        public int Added { get; private set; }

        public Task AddShieldAsync(Guid userId, CancellationToken ct = default)
        {
            Added++;
            return Task.CompletedTask;
        }
    }

    private sealed class NoopItemGrantPort : ILevelUpItemGrantPort
    {
        public Task<IReadOnlyList<GrantedItemInfo>> EvaluateAndGrantAsync(Guid userId, int previousLevel,
            int newLevel, CancellationToken ct = default) => Task.FromResult<IReadOnlyList<GrantedItemInfo>>([]);
    }

    private sealed class NoopEventPublisher : IEventPublisher
    {
        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
            where TEvent : IDomainEvent => Task.CompletedTask;
    }
}
