using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Application.UseCases;
using LifeLevel.Modules.Character.Domain.Data;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;

using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;

namespace LifeLevel.Api.Tests;

public class TitleServiceTests
{
    [Fact]
    public async Task CheckAndGrantTitlesAsync_GrantsAllCriteriaTitles_AndUpdatesRank()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var character = new CharacterEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Rank = "Novice",
        };
        db.Characters.Add(character);
        SeedTitlesAndRanks(db);
        await db.SaveChangesAsync();

        var events = new RecordingEventPublisher();
        var service = new TitleService(
            db,
            new FakeBossCountPort(18),
            new FakeStreakReadPort(30),
            new FakeDailyQuestReadPort(5),
            events);

        await service.CheckAndGrantTitlesAsync(userId);

        var earnedNames = await db.CharacterTitles
            .Where(ct => ct.CharacterId == character.Id)
            .Join(db.Titles, ct => ct.TitleId, t => t.Id, (_, t) => t.Name)
            .OrderBy(n => n)
            .ToListAsync();
        var updatedCharacter = await db.Characters.SingleAsync(c => c.Id == character.Id);

        Assert.Equal("Legend", updatedCharacter.Rank);
        Assert.Contains("The Marathoner", earnedNames);
        Assert.Contains("Streak Master", earnedNames);
        Assert.Contains("Raid Veteran", earnedNames);
        Assert.Contains("5AM Club", earnedNames);
        Assert.Contains("The Champion", earnedNames);
        Assert.Contains("The Unstoppable", earnedNames);
        Assert.DoesNotContain("Novice Adventurer", earnedNames);
        Assert.Contains(events.Published, e =>
            e is CharacterRankChangedEvent rankChanged &&
            rankChanged.UserId == userId &&
            rankChanged.NewRank == "Legend");
    }

    [Fact]
    public async Task GetTitlesAndRanksAsync_BackfillsEarnedCriteriaTitlesBeforeReturning()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        db.Characters.Add(new CharacterEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Rank = "Novice",
        });
        SeedTitlesAndRanks(db);
        await db.SaveChangesAsync();

        var service = new TitleService(
            db,
            new FakeBossCountPort(3),
            new FakeStreakReadPort(0),
            new FakeDailyQuestReadPort(5),
            new RecordingEventPublisher());

        var result = await service.GetTitlesAndRanksAsync(userId);

        Assert.Equal("Veteran", result.RankProgression.CurrentRank);
        Assert.Contains(result.EarnedTitles, t => t.Name == "The Marathoner");
        Assert.Contains(result.EarnedTitles, t => t.Name == "Raid Veteran");
    }

    [Fact]
    public async Task TitleUnlockAdapter_GrantsNoviceAdventurerByStableKey()
    {
        await using var db = CreateDb();
        var characterId = Guid.NewGuid();
        db.Characters.Add(new CharacterEntity
        {
            Id = characterId,
            UserId = Guid.NewGuid(),
        });
        SeedTitlesAndRanks(db);
        await db.SaveChangesAsync();

        var adapter = new TitleUnlockAdapter(
            db,
            NullLogger<TitleUnlockAdapter>.Instance);

        var granted = await adapter.UnlockAsync(characterId, "novice-adventurer");
        var noviceId = TitleCatalog.KeyToId["novice-adventurer"];

        Assert.True(granted);
        Assert.True(await db.CharacterTitles.AnyAsync(ct =>
            ct.CharacterId == characterId &&
            ct.TitleId == noviceId));
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static void SeedTitlesAndRanks(AppDbContext db)
    {
        foreach (var (id, emoji, name, unlockCondition, unlockCriteria, sortOrder) in TitleCatalog.Titles)
        {
            db.Titles.Add(new Title
            {
                Id = id,
                Emoji = emoji,
                Name = name,
                UnlockCondition = unlockCondition,
                UnlockCriteria = unlockCriteria,
                SortOrder = sortOrder,
            });
        }

        db.RankThresholds.AddRange(
            new RankThreshold { Id = Guid.NewGuid(), Rank = "Novice", DisplayName = "Novice", BossesRequired = 0 },
            new RankThreshold { Id = Guid.NewGuid(), Rank = "Warrior", DisplayName = "Warrior", BossesRequired = 1 },
            new RankThreshold { Id = Guid.NewGuid(), Rank = "Veteran", DisplayName = "Veteran", BossesRequired = 3 },
            new RankThreshold { Id = Guid.NewGuid(), Rank = "Champion", DisplayName = "Champion", BossesRequired = 8 },
            new RankThreshold { Id = Guid.NewGuid(), Rank = "Legend", DisplayName = "Legend", BossesRequired = 18 });
    }

    private sealed class FakeBossCountPort(int count) : IBossDefeatedCountReadPort
    {
        public Task<int> GetDefeatedCountAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(count);
    }

    private sealed class FakeStreakReadPort(int current) : IStreakReadPort
    {
        public Task<StreakReadDto?> GetCurrentStreakAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult<StreakReadDto?>(new StreakReadDto(current, current, 0));
    }

    private sealed class FakeDailyQuestReadPort(int count) : IDailyQuestReadPort
    {
        public Task<int> CountCompletedDailyQuestsAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(count);
    }

    private sealed class RecordingEventPublisher : IEventPublisher
    {
        public List<IDomainEvent> Published { get; } = [];

        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
            where TEvent : IDomainEvent
        {
            Published.Add(e);
            return Task.CompletedTask;
        }
    }
}
