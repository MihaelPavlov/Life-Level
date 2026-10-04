using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Application.UseCases;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class UnlockServiceTests
{
    private static readonly UnlockFacts NewPlayer = new(
        SetupComplete: true, ActivityCount: 0, HasDistance: false, ItemCount: 0,
        ZonesReached: 1, Level: 1, LongestStreak: 0, BossSeen: false);

    [Fact]
    public async Task NewPlayer_GetsHomeWithACeremonyAndTour()
    {
        await using var db = CreateDb();
        var service = new UnlockService(db, new FixedFacts(NewPlayer), new RecordingCoins());

        var list = (await service.GetAsync(Guid.NewGuid())).Unlocks;

        var home = list.Single(u => u.Key == "home");
        Assert.True(home.Unlocked);
        Assert.False(home.Seen);
        Assert.False(home.Toured);
        Assert.All(list.Where(u => u.Key != "home"), u => Assert.False(u.Unlocked));
        Assert.Equal(UnlockService.Catalog.Count, list.Count);
    }

    [Fact]
    public async Task NewPlayer_WithoutWorkouts_GetsOnlyHome()
    {
        await using var db = CreateDb();
        var service = new UnlockService(db, new FixedFacts(NewPlayer with { Level = 1 }), new RecordingCoins());

        var list = (await service.GetAsync(Guid.NewGuid())).Unlocks;

        Assert.Equal(["home"], list.Where(u => u.Unlocked).Select(u => u.Key));
    }

    [Fact]
    public async Task FirstWorkout_OpensOnlyTheMap_AtLevelOne()
    {
        await using var db = CreateDb();
        var facts = new FixedFacts(NewPlayer);
        var service = new UnlockService(db, facts, new RecordingCoins());
        var userId = Guid.NewGuid();
        await service.GetAsync(userId);

        facts.Value = NewPlayer with { ActivityCount = 1, HasDistance = true, Level = 1 };
        var list = (await service.GetAsync(userId)).Unlocks;

        var map = list.Single(x => x.Key == "map");
        Assert.True(map.Unlocked);
        Assert.False(map.Seen);
        Assert.False(list.Single(x => x.Key == "achievements").Unlocked);
    }

    [Fact]
    public async Task OneWorkoutAcrossTwoTiers_ReleasesOnlyTheLowest_AndTheNextWaitsForAWorkout()
    {
        await using var db = CreateDb();
        var facts = new FixedFacts(NewPlayer);
        var service = new UnlockService(db, facts, new RecordingCoins());
        var userId = Guid.NewGuid();
        await service.GetAsync(userId);
        facts.Value = NewPlayer with { ActivityCount = 1, HasDistance = true };
        await service.GetAsync(userId);
        await service.MarkSeenAsync(userId, "map");

        // One big workout: Level 3 with an item and a 3-day streak qualifies tiers 2 and 3.
        facts.Value = NewPlayer with { ActivityCount = 2, HasDistance = true, ItemCount = 1, Level = 3, LongestStreak = 3 };
        var list = (await service.GetAsync(userId)).Unlocks;
        Assert.Equal(["home", "map", "achievements", "gear"], list.Where(u => u.Unlocked).Select(u => u.Key));

        // Ceremonies still unseen: nothing else is released.
        await service.MarkSeenAsync(userId, "achievements");
        list = (await service.GetAsync(userId)).Unlocks;
        Assert.False(list.Single(u => u.Key == "talents").Unlocked);

        // Queue empty, but no new workout yet: tier 3 waits.
        await service.MarkSeenAsync(userId, "gear");
        list = (await service.GetAsync(userId)).Unlocks;
        Assert.False(list.Single(u => u.Key == "talents").Unlocked);

        // The next workout opens tier 3, both features together.
        facts.Value = facts.Value with { ActivityCount = 3 };
        list = (await service.GetAsync(userId)).Unlocks;
        Assert.True(list.Single(u => u.Key == "talents").Unlocked);
        Assert.True(list.Single(u => u.Key == "shields").Unlocked);
        Assert.False(list.Single(u => u.Key == "chests").Unlocked);
    }

    [Fact]
    public async Task PartnerOfAnOpenTier_OpensWithoutANewWorkout()
    {
        await using var db = CreateDb();
        var facts = new FixedFacts(NewPlayer with { ActivityCount = 1, HasDistance = true, Level = 2 });
        var service = new UnlockService(db, facts, new RecordingCoins());
        var userId = Guid.NewGuid();
        await service.GetAsync(userId);
        await service.MarkSeenAsync(userId, "map");
        facts.Value = facts.Value with { ActivityCount = 2 };
        await service.GetAsync(userId);                 // achievements (no item yet, so no gear)
        await service.MarkSeenAsync(userId, "achievements");

        facts.Value = facts.Value with { ItemCount = 1 }; // a chest item, no new workout
        var list = (await service.GetAsync(userId)).Unlocks;

        Assert.True(list.Single(u => u.Key == "gear").Unlocked);
    }

    [Theory]
    [InlineData(2, "talents", false)]
    [InlineData(3, "talents", true)]
    [InlineData(5, "leaderboard", false)]
    [InlineData(6, "leaderboard", true)]
    [InlineData(7, "guild", false)]
    [InlineData(8, "guild", true)]
    [InlineData(9, "modes", false)]
    [InlineData(10, "modes", true)]
    [InlineData(14, "delve", false)]
    [InlineData(15, "delve", true)]
    public void LevelThresholds(int level, string key, bool unlocked)
    {
        var def = UnlockService.Catalog.Single(d => d.Key == key);
        Assert.Equal(unlocked, def.IsMet(NewPlayer with { Level = level }));
    }

    [Theory]
    [InlineData(false, 0, false)]
    [InlineData(true, 0, true)]
    [InlineData(false, 1, true)]
    public void Ranks_OpenOnFirstRankOrTitle(bool rankReached, int titles, bool unlocked)
    {
        var def = UnlockService.Catalog.Single(d => d.Key == "ranks");
        Assert.Equal(unlocked, def.IsMet(NewPlayer with { Level = 5, RankReached = rankReached, TitlesEarned = titles }));
        Assert.False(def.IsMet(NewPlayer with { Level = 4, RankReached = true }));
    }

    [Fact]
    public void EveryTier_HoldsAtMostTwoFeatures()
    {
        Assert.All(UnlockService.Catalog.GroupBy(d => d.Tier), g => Assert.True(g.Count() <= 2, $"tier {g.Key}"));
        Assert.Equal(UnlockService.Catalog.OrderBy(d => d.Tier).Select(d => d.Key), UnlockService.Catalog.Select(d => d.Key));
    }

    [Theory]
    [InlineData("gear", 1, false)]
    [InlineData("gear", 2, true)]
    [InlineData("shields", 2, false)]
    [InlineData("chests", 3, false)]
    [InlineData("bosses", 4, true)]
    public void ActionsWaitForTheirLevel(string key, int level, bool unlocked)
    {
        var def = UnlockService.Catalog.Single(d => d.Key == key);
        var did = NewPlayer with { ItemCount = 1, LongestStreak = 5, ZonesReached = 3, BossSeen = true, Level = level };
        Assert.Equal(unlocked, def.IsMet(did));
    }

    [Fact]
    public async Task ExistingPlayer_IsBackFilledSilently()
    {
        await using var db = CreateDb();
        var veteran = NewPlayer with
        {
            ActivityCount = 40, HasDistance = true, ItemCount = 6, ZonesReached = 9,
            Level = 12, LongestStreak = 8, BossSeen = true, RankReached = true,
        };
        var service = new UnlockService(db, new FixedFacts(veteran), new RecordingCoins());

        var list = (await service.GetAsync(Guid.NewGuid())).Unlocks;

        Assert.All(list.Where(u => u.Key != "delve"), u =>
        {
            Assert.True(u.Unlocked, u.Key);
            Assert.True(u.Seen && u.Toured, u.Key);
        });
        Assert.False(list.Single(u => u.Key == "delve").Unlocked);
    }

    [Fact]
    public async Task NewPlayerWithImportedHistory_GetsTierOneFirst()
    {
        await using var db = CreateDb();
        var imported = NewPlayer with
        {
            ActivityCount = 12, HasDistance = true, Level = 3,
            CharacterCreatedAt = UnlockService.BackFillBefore.AddDays(1),
        };
        var service = new UnlockService(db, new FixedFacts(imported), new RecordingCoins());

        var list = (await service.GetAsync(Guid.NewGuid())).Unlocks;

        Assert.Equal(["home", "map"], list.Where(u => u.Unlocked).Select(u => u.Key));
        Assert.All(list.Where(u => u.Unlocked), u => Assert.False(u.Seen || u.Toured, u.Key));
    }

    [Fact]
    public async Task GetIsIdempotent()
    {
        await using var db = CreateDb();
        var service = new UnlockService(db, new FixedFacts(NewPlayer with { ActivityCount = 1, HasDistance = true }), new RecordingCoins());
        var userId = Guid.NewGuid();

        await service.GetAsync(userId);
        await service.GetAsync(userId);

        Assert.Equal(2, await db.Set<CharacterUnlock>().CountAsync(u => u.UserId == userId));
    }

    [Fact]
    public async Task Toured_AwardsCoinsOnce_NeverXp_AndMarksSeen()
    {
        await using var db = CreateDb();
        var coins = new RecordingCoins();
        var facts = new FixedFacts(NewPlayer);
        var service = new UnlockService(db, facts, coins);
        var userId = Guid.NewGuid();
        await service.GetAsync(userId);
        facts.Value = NewPlayer with { ActivityCount = 1, HasDistance = true };
        await service.GetAsync(userId);

        var first = await service.MarkTouredAsync(userId, "map");
        var again = await service.MarkTouredAsync(userId, "map");

        Assert.Equal(UnlockService.TourCoins, first.CoinsAwarded);
        Assert.Equal(0, first.XpAwarded);
        Assert.Equal(0, again.CoinsAwarded);
        Assert.Equal(UnlockService.TourCoins, coins.Total);
        var row = (await service.GetAsync(userId)).Unlocks.Single(u => u.Key == "map");
        Assert.True(row.Seen && row.Toured);
    }

    [Fact]
    public async Task LockedOrUnknownKeys_AreRejected()
    {
        await using var db = CreateDb();
        var service = new UnlockService(db, new FixedFacts(NewPlayer), new RecordingCoins());
        var userId = Guid.NewGuid();
        await service.GetAsync(userId);

        await Assert.ThrowsAsync<InvalidOperationException>(() => service.MarkSeenAsync(userId, "guild"));
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.MarkTouredAsync(userId, "nope"));
    }

    private static AppDbContext CreateDb() => new(
        new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private sealed class FixedFacts(UnlockFacts value) : IUnlockFactsReadPort
    {
        public UnlockFacts Value { get; set; } = value;
        public Task<UnlockFacts> GetAsync(Guid userId, CancellationToken ct = default) => Task.FromResult(Value);
    }

    private sealed class RecordingCoins : IRewardCurrencyPort
    {
        public long Total { get; private set; }

        public Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default)
        {
            Total += amount;
            return Task.CompletedTask;
        }

        public Task AddGemsAsync(Guid userId, int amount, CancellationToken ct = default) => Task.CompletedTask;
        public Task AddTalentCrystalsAsync(Guid userId, int amount, CancellationToken ct = default) => Task.CompletedTask;
    }
}
