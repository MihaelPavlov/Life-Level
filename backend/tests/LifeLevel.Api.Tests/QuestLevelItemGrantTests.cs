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

public class QuestLevelItemGrantTests
{
    [Fact]
    public async Task UpdateProgressFromActivityAsync_WhenQuestXpLevelsUp_EvaluatesLevelItemRewards()
    {
        var userId = Guid.NewGuid();
        var quest = new Quest
        {
            Id = Guid.NewGuid(),
            Title = "Run once",
            Description = "Complete one run",
            Type = QuestType.Special,
            Category = QuestCategory.Workouts,
            RequiredActivity = ActivityType.Running,
            TargetValue = 1,
            TargetUnit = "workout",
            RewardXp = 300,
            IsActive = true,
        };

        await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);
        db.Quests.Add(quest);
        db.UserQuestProgress.Add(new UserQuestProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            QuestId = quest.Id,
            CurrentValue = 0,
            IsCompleted = false,
            RewardClaimed = false,
            AssignedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(1),
        });
        await db.SaveChangesAsync();

        var itemGrant = new CapturingLevelUpItemGrantPort();
        var service = new QuestService(
            db,
            new StubCharacterXpPort(new XpAwardResult(true, 4, 5)),
            new NoopEventPublisher(),
            itemGrant);

        await service.UpdateProgressFromActivityAsync(
            userId,
            ActivityType.Running,
            durationMinutes: 20,
            distanceKm: 3,
            calories: 200);

        Assert.Equal(userId, itemGrant.UserId);
        Assert.Equal(4, itemGrant.PreviousLevel);
        Assert.Equal(5, itemGrant.NewLevel);
        Assert.Equal(1, itemGrant.Calls);
    }

    private sealed class StubCharacterXpPort(XpAwardResult result) : ICharacterXpPort
    {
        public Task<XpAwardResult> AwardXpAsync(
            Guid userId,
            string source,
            string sourceEmoji,
            string description,
            long xp,
            CancellationToken ct = default) => Task.FromResult(result);
    }

    private sealed class CapturingLevelUpItemGrantPort : ILevelUpItemGrantPort
    {
        public int Calls { get; private set; }
        public Guid? UserId { get; private set; }
        public int? PreviousLevel { get; private set; }
        public int? NewLevel { get; private set; }

        public Task<IReadOnlyList<GrantedItemInfo>> EvaluateAndGrantAsync(
            Guid userId,
            int previousLevel,
            int newLevel,
            CancellationToken ct = default)
        {
            Calls++;
            UserId = userId;
            PreviousLevel = previousLevel;
            NewLevel = newLevel;
            return Task.FromResult<IReadOnlyList<GrantedItemInfo>>([]);
        }
    }

    private sealed class NoopEventPublisher : IEventPublisher
    {
        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
            where TEvent : IDomainEvent => Task.CompletedTask;
    }
}
