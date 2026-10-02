using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Activity.Application.UseCases;
using ActivityEntity = LifeLevel.Modules.Activity.Domain.Entities.Activity;
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
    public async Task GetSummaryAsync_SumsOnlyTheUsersActivitySteps()
    {
        var userId = Guid.NewGuid();
        var characterId = Guid.NewGuid();
        var otherCharacterId = Guid.NewGuid();
        await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);
        db.Set<ActivityEntity>().AddRange(
            new ActivityEntity { Id = Guid.NewGuid(), CharacterId = characterId, Steps = 2_100 },
            new ActivityEntity { Id = Guid.NewGuid(), CharacterId = characterId, Steps = 3_400 },
            new ActivityEntity { Id = Guid.NewGuid(), CharacterId = otherCharacterId, Steps = 9_999 });
        await db.SaveChangesAsync();
        var service = CreateService(db, characterId, new CapturingLevelUpItemGrantPort());

        var summary = await service.GetSummaryAsync(userId);

        Assert.Equal(5_500, summary.TotalSteps);
    }

    [Fact]
    public async Task GetCalendarAsync_GroupsRecentDaysAndFindsTheLongestRun()
    {
        var characterId = Guid.NewGuid();
        await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);
        var today = DateTime.UtcNow.Date;
        db.Set<ActivityEntity>().AddRange(
            new ActivityEntity { Id = Guid.NewGuid(), CharacterId = characterId, Type = ActivityType.Running, DistanceKm = 5, XpGained = 100, LoggedAt = today.AddHours(7) },
            new ActivityEntity { Id = Guid.NewGuid(), CharacterId = characterId, Type = ActivityType.Gym, DistanceKm = 0, XpGained = 80, LoggedAt = today.AddHours(18) },
            new ActivityEntity { Id = Guid.NewGuid(), CharacterId = characterId, Type = ActivityType.Cycling, DistanceKm = 20, XpGained = 150, LoggedAt = today.AddDays(-3) },
            // Outside the window, but still the longest run ever.
            new ActivityEntity { Id = Guid.NewGuid(), CharacterId = characterId, Type = ActivityType.Running, DistanceKm = 12.4, XpGained = 300, LoggedAt = today.AddDays(-400) },
            new ActivityEntity { Id = Guid.NewGuid(), CharacterId = Guid.NewGuid(), Type = ActivityType.Running, DistanceKm = 42, LoggedAt = today });
        await db.SaveChangesAsync();
        var service = CreateService(db, characterId, new CapturingLevelUpItemGrantPort());

        var calendar = await service.GetCalendarAsync(Guid.NewGuid(), days: 84);

        Assert.Equal(12.4, calendar.LongestRunKm);
        Assert.Equal(2, calendar.Days.Count);
        var todayRow = calendar.Days.Single(d => d.Date == DateOnly.FromDateTime(today));
        Assert.Equal(2, todayRow.Workouts);
        Assert.Equal(5, todayRow.DistanceKm);
        Assert.Equal(180, todayRow.Xp);
    }

    [Fact]
    public async Task LogExternalActivityAsync_WhenLevelingUp_DefersItemsToLevelUpEvent()
    {
        var userId = Guid.NewGuid();
        var characterId = Guid.NewGuid();
        await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);
        var itemGrant = new CapturingLevelUpItemGrantPort();
        var service = CreateService(
            db,
            characterId,
            itemGrant,
            new XpAwardResult(true, 4, 9));

        await service.LogExternalActivityAsync(
            userId,
            ActivityType.Running,
            durationMinutes: 30,
            distanceKm: 5,
            calories: 300,
            heartRateAvg: null,
            externalId: "sync-1",
            performedAt: DateTime.UtcNow);

        Assert.Equal(0, itemGrant.Calls);
    }

    private static ActivityService CreateService(
        AppDbContext db,
        Guid characterId,
        CapturingLevelUpItemGrantPort itemGrant,
        XpAwardResult? xpResult = null) =>
        new(
            db,
            new StubCharacterXpPort(xpResult ?? new XpAwardResult(false, 1, 1)),
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
