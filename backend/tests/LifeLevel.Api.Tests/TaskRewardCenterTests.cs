using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Quest.Application.UseCases;
using LifeLevel.Modules.Quest.Domain.Entities;
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
    public async Task GetRewardPeriodAsync_AssignsTenDailyTasks_WithExpectedRewardMix()
    {
        await using var db = CreateDb();
        db.Quests.AddRange(Enumerable.Range(1, 10).Select(index => new Quest
        {
            Id = Guid.NewGuid(),
            Title = $"Daily task {index}",
            Description = "Complete a workout.",
            Type = QuestType.Daily,
            Category = QuestCategory.Workouts,
            TargetValue = 1,
            TargetUnit = "workout",
            IsActive = true,
            SortOrder = index,
        }));
        await db.SaveChangesAsync();

        var period = await CreateService(db).GetRewardPeriodAsync(Guid.NewGuid(), QuestType.Daily);

        Assert.Equal(10, period.Tasks.Count);
        Assert.All(period.Tasks, task => Assert.Equal(10, task.RewardPoints));
        Assert.Equal(9, period.Tasks.Count(task => task.RewardCoins == 15));
        Assert.Single(period.Tasks, task => task.RewardCrystals == 1);
        Assert.Equal([20, 40, 60, 80, 100], period.Milestones.Select(m => m.Threshold));
        Assert.Equal(100, period.PointsMaximum);
        Assert.Equal(DateTime.UtcNow.Date.AddDays(1), period.ResetAtUtc);
    }

    [Fact]
    public async Task CompletingDailyTask_AutoGrantsTaskReward_AndUnlocksPoints()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        db.Quests.AddRange(Enumerable.Range(1, 10).Select(index => new Quest
        {
            Id = Guid.NewGuid(),
            Title = $"Daily task {index}",
            Description = "Complete a workout.",
            Type = QuestType.Daily,
            Category = QuestCategory.Workouts,
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
        var period = await service.GetRewardPeriodAsync(userId, QuestType.Daily);

        Assert.Equal(100, period.PointsEarned);
        Assert.Equal(135, currency.Coins);
        Assert.Equal(1, currency.Crystals);
        Assert.All(period.Milestones, milestone => Assert.True(milestone.IsUnlocked));
    }

    private static AppDbContext CreateDb() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static QuestService CreateService(AppDbContext db, IRewardCurrencyPort? currency = null) =>
        new(db, new StubXpPort(), new NoopEventPublisher(), new NoopItemGrantPort(), rewardCurrency: currency);

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
