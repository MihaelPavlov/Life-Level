using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Activity.Application.UseCases;
using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;

namespace LifeLevel.Api.Tests;

public class ActivityServiceExternalItemGrantTests
{
    [Fact]
    public async Task LogExternalActivityAsync_WhenLevelingUp_EvaluatesLevelItemRewards()
    {
        var userId = Guid.NewGuid();
        var characterId = Guid.NewGuid();
        await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);
        var itemGrant = new CapturingLevelUpItemGrantPort();
        var service = new ActivityService(
            db,
            new StubCharacterXpPort(new XpAwardResult(true, 4, 9)),
            new NoopCharacterStatPort(),
            new StubCharacterIdReadPort(characterId),
            new NoopEventPublisher(),
            new NullStreakReadPort(),
            new NoopQuestProgressPort(),
            new NullWorldZoneDistancePort(),
            new EmptyGearBonusReadPort(),
            itemGrant,
            new EmptyZoneUnlockReadPort(),
            new NoopCharacterTutorialPort(),
            NullLogger<ActivityService>.Instance);

        await service.LogExternalActivityAsync(
            userId,
            ActivityType.Running,
            durationMinutes: 30,
            distanceKm: 5,
            calories: 300,
            heartRateAvg: null,
            externalId: "sync-1",
            performedAt: DateTime.UtcNow);

        Assert.Equal(userId, itemGrant.UserId);
        Assert.Equal(4, itemGrant.PreviousLevel);
        Assert.Equal(9, itemGrant.NewLevel);
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

    private sealed class NoopCharacterStatPort : ICharacterStatPort
    {
        public Task ApplyStatGainsAsync(Guid userId, StatGains gains, CancellationToken ct = default) =>
            Task.CompletedTask;
    }

    private sealed class NoopEventPublisher : IEventPublisher
    {
        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
            where TEvent : IDomainEvent => Task.CompletedTask;
    }

    private sealed class NullStreakReadPort : IStreakReadPort
    {
        public Task<StreakReadDto?> GetCurrentStreakAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult<StreakReadDto?>(null);
    }

    private sealed class NoopQuestProgressPort : IQuestProgressPort
    {
        public Task<QuestActivityResult> UpdateProgressFromActivityAsync(
            Guid userId,
            ActivityType activityType,
            int durationMinutes,
            double? distanceKm,
            int? calories,
            CancellationToken ct = default) =>
            Task.FromResult(new QuestActivityResult([], false, 0));
    }

    private sealed class NullWorldZoneDistancePort : IWorldZoneDistancePort
    {
        public Task<ActiveEncounterPortDto?> AddDistanceAsync(
            Guid userId,
            double km,
            CancellationToken ct = default) =>
            Task.FromResult<ActiveEncounterPortDto?>(null);
    }

    private sealed class EmptyGearBonusReadPort : IGearBonusReadPort
    {
        public Task<GearBonuses> GetEquippedBonusesAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(GearBonuses.Empty);
    }

    private sealed class EmptyZoneUnlockReadPort : IZoneUnlockReadPort
    {
        public Task<IReadOnlyList<UnlockedZoneInfo>> GetZonesUnlockedInRangeAsync(
            int previousLevel,
            int newLevel,
            CancellationToken ct = default) =>
            Task.FromResult<IReadOnlyList<UnlockedZoneInfo>>([]);
    }

    private sealed class NoopCharacterTutorialPort : ICharacterTutorialPort
    {
        public Task<int> AdvanceIfOnStepAsync(Guid characterId, int expectedStep, CancellationToken ct = default) =>
            Task.FromResult(expectedStep);
    }
}
