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
        var service = new UnlockService(db, new FixedFacts(NewPlayer), new RecordingXp());

        var list = (await service.GetAsync(Guid.NewGuid())).Unlocks;

        var home = list.Single(u => u.Key == "home");
        Assert.True(home.Unlocked);
        Assert.False(home.Seen);
        Assert.False(home.Toured);
        Assert.All(list.Where(u => u.Key != "home"), u => Assert.False(u.Unlocked));
        Assert.Equal(UnlockService.Catalog.Count, list.Count);
    }

    [Fact]
    public async Task LaterUnlocks_ArriveUnseen()
    {
        await using var db = CreateDb();
        var facts = new FixedFacts(NewPlayer);
        var service = new UnlockService(db, facts, new RecordingXp());
        var userId = Guid.NewGuid();
        await service.GetAsync(userId);

        facts.Value = NewPlayer with { ActivityCount = 1, HasDistance = true, Level = 3 };
        var list = (await service.GetAsync(userId)).Unlocks;

        foreach (var key in new[] { "achievements", "map", "talents" })
        {
            var u = list.Single(x => x.Key == key);
            Assert.True(u.Unlocked, key);
            Assert.False(u.Seen, key);
        }
        Assert.False(list.Single(x => x.Key == "guild").Unlocked);
    }

    [Theory]
    [InlineData(2, "talents", false)]
    [InlineData(3, "talents", true)]
    [InlineData(4, "guild", false)]
    [InlineData(5, "guild", true)]
    [InlineData(5, "leaderboard", false)]
    [InlineData(6, "leaderboard", true)]
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
        Assert.Equal(unlocked, def.IsMet(NewPlayer with { RankReached = rankReached, TitlesEarned = titles }));
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
        var service = new UnlockService(db, new FixedFacts(veteran), new RecordingXp());

        var list = (await service.GetAsync(Guid.NewGuid())).Unlocks;

        Assert.All(list.Where(u => u.Key != "delve"), u =>
        {
            Assert.True(u.Unlocked, u.Key);
            Assert.True(u.Seen && u.Toured, u.Key);
        });
        Assert.False(list.Single(u => u.Key == "delve").Unlocked);
    }

    [Fact]
    public async Task NewPlayerWithImportedHistory_GetsEveryCeremony()
    {
        await using var db = CreateDb();
        var imported = NewPlayer with
        {
            ActivityCount = 12, HasDistance = true, Level = 4,
            CharacterCreatedAt = UnlockService.BackFillBefore.AddDays(1),
        };
        var service = new UnlockService(db, new FixedFacts(imported), new RecordingXp());

        var list = (await service.GetAsync(Guid.NewGuid())).Unlocks;

        foreach (var key in new[] { "home", "achievements", "map", "talents" })
        {
            var u = list.Single(x => x.Key == key);
            Assert.True(u.Unlocked, key);
            Assert.False(u.Seen || u.Toured, key);
        }
    }

    [Fact]
    public async Task GetIsIdempotent()
    {
        await using var db = CreateDb();
        var service = new UnlockService(db, new FixedFacts(NewPlayer with { ActivityCount = 1 }), new RecordingXp());
        var userId = Guid.NewGuid();

        await service.GetAsync(userId);
        await service.GetAsync(userId);

        Assert.Equal(2, await db.Set<CharacterUnlock>().CountAsync(u => u.UserId == userId));
    }

    [Fact]
    public async Task Toured_AwardsXpOnce_AndMarksSeen()
    {
        await using var db = CreateDb();
        var xp = new RecordingXp();
        var facts = new FixedFacts(NewPlayer);
        var service = new UnlockService(db, facts, xp);
        var userId = Guid.NewGuid();
        await service.GetAsync(userId);
        facts.Value = NewPlayer with { ActivityCount = 1 };
        await service.GetAsync(userId);

        var first = await service.MarkTouredAsync(userId, "achievements");
        var again = await service.MarkTouredAsync(userId, "achievements");

        Assert.Equal(UnlockService.TourXp, first.XpAwarded);
        Assert.Equal(0, again.XpAwarded);
        Assert.Equal(UnlockService.TourXp, xp.Total);
        var row = (await service.GetAsync(userId)).Unlocks.Single(u => u.Key == "achievements");
        Assert.True(row.Seen && row.Toured);
    }

    [Fact]
    public async Task LockedOrUnknownKeys_AreRejected()
    {
        await using var db = CreateDb();
        var service = new UnlockService(db, new FixedFacts(NewPlayer), new RecordingXp());
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

    private sealed class RecordingXp : ICharacterXpPort
    {
        public long Total { get; private set; }

        public Task<XpAwardResult> AwardXpAsync(Guid userId, string source, string sourceEmoji,
            string description, long xp, CancellationToken ct = default)
        {
            Total += xp;
            return Task.FromResult(XpAwardResult.None);
        }
    }
}
