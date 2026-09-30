using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Leaderboard.Application.UseCases;
using LifeLevel.Modules.Leaderboard.Domain;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class LeaderboardServiceTests
{
    private static readonly Guid Me = Guid.NewGuid();
    private static readonly Guid Vex = Guid.NewGuid();
    private static readonly Guid Mira = Guid.NewGuid();
    private static readonly Guid Aria = Guid.NewGuid();

    [Fact]
    public async Task Get_RanksByScore_AndPinsMyRowWithTheGapToTheNextPlayer()
    {
        await using var db = CreateDb();
        var board = new FakeBoard(("Aria", Aria, 900), ("Me", Me, 500), ("Vex", Vex, 700));
        var service = new LeaderboardService(db, board, new RecordingCurrency());

        var dto = await service.GetAsync(Me, LeaderboardScope.Global, LeaderboardMetric.Xp);

        Assert.Equal(["Aria", "Vex", "Me"], dto.Entries.Select(e => e.Username));
        Assert.True(dto.Entries[2].IsMe);
        Assert.Equal(3, dto.Me.Rank);
        Assert.Equal("Vex", dto.Me.NextUsername);
        Assert.Equal(200, dto.Me.GapToNext);
        Assert.NotNull(dto.ResetsAtUtc);
    }

    [Fact]
    public async Task Power_NeverResets()
    {
        await using var db = CreateDb();
        var service = new LeaderboardService(db, new FakeBoard(("Me", Me, 1)), new RecordingCurrency());

        var dto = await service.GetAsync(Me, LeaderboardScope.Global, LeaderboardMetric.Power);

        Assert.Null(dto.ResetsAtUtc);
    }

    [Fact]
    public async Task UnavailableScope_StillReturnsAnEmptyBoard()
    {
        await using var db = CreateDb();
        var board = new FakeBoard(("Me", Me, 1)) { Unavailable = true };
        var service = new LeaderboardService(db, board, new RecordingCurrency());

        var dto = await service.GetAsync(Me, LeaderboardScope.Guild, LeaderboardMetric.Xp);

        Assert.False(dto.Available);
        Assert.Empty(dto.Entries);
        Assert.Null(dto.Me.Rank);
    }

    [Fact]
    public async Task PassingPlayers_StacksOneRewardEachInTheChest()
    {
        await using var db = CreateDb();
        var board = new FakeBoard(("Aria", Aria, 900), ("Mira", Mira, 800), ("Vex", Vex, 700), ("Me", Me, 500));
        var service = new LeaderboardService(db, board, new RecordingCurrency());
        Assert.Equal(0, (await service.GetChestStatusAsync(Me)).Stack);

        board.Set(Me, 850);
        var chest = await service.GetChestStatusAsync(Me);

        Assert.Equal(2, chest.Stack);
        // Climbed to rank 2: both passes pay the top-3 reward.
        var (coins, gems) = LeaderboardRules.PassReward(2);
        Assert.Equal(coins * 2, chest.Coins);
        Assert.Equal(gems * 2, chest.Gems);
    }

    [Fact]
    public async Task APass_PaysOncePerPlayerPerWeek()
    {
        await using var db = CreateDb();
        var board = new FakeBoard(("Vex", Vex, 700), ("Me", Me, 500));
        var service = new LeaderboardService(db, board, new RecordingCurrency());
        await service.GetChestStatusAsync(Me);

        board.Set(Me, 800);
        await service.GetChestStatusAsync(Me);
        board.Set(Vex, 900);
        await service.GetChestStatusAsync(Me);
        board.Set(Me, 1000);
        var chest = await service.GetChestStatusAsync(Me);

        Assert.Equal(1, chest.Stack);
    }

    [Fact]
    public async Task OpeningTheChest_PaysTheStackAndEmptiesIt()
    {
        await using var db = CreateDb();
        var board = new FakeBoard(("Mira", Mira, 800), ("Vex", Vex, 700), ("Me", Me, 500));
        var currency = new RecordingCurrency();
        var service = new LeaderboardService(db, board, currency);
        await service.GetChestStatusAsync(Me);
        board.Set(Me, 900);
        var before = await service.GetChestStatusAsync(Me);

        var opened = await service.OpenChestAsync(Me);

        Assert.Equal(before.Coins, opened.Coins);
        Assert.Equal(before.Gems, opened.Gems);
        Assert.Equal(["Mira", "Vex"], opened.Passes.Select(p => p.Username).Order());
        Assert.Equal(before.Coins, currency.Coins);
        Assert.Equal(before.Gems, currency.Gems);
        Assert.Equal(0, (await service.GetChestStatusAsync(Me)).Stack);
        Assert.Empty((await service.OpenChestAsync(Me)).Passes);
        Assert.Equal(before.Coins, currency.Coins);
    }

    [Fact]
    public async Task PaidPasses_AreCappedPerWeek()
    {
        await using var db = CreateDb();
        var players = Enumerable.Range(0, LeaderboardRules.MaxPaidPassesPerWeek + 5)
            .Select(i => ($"P{i}", Guid.NewGuid(), 600.0 + i)).ToList();
        var board = new FakeBoard([.. players, ("Me", Me, 500)]);
        var service = new LeaderboardService(db, board, new RecordingCurrency());
        await service.GetChestStatusAsync(Me);

        board.Set(Me, 10_000);
        var chest = await service.GetChestStatusAsync(Me);

        // Only the nearest WatchDepth players ahead are watched, and pay is capped.
        Assert.Equal(Math.Min(LeaderboardRules.WatchDepth, LeaderboardRules.MaxPaidPassesPerWeek), chest.Stack);
    }

    [Theory]
    [InlineData("2026-09-28T00:00:00Z", "2026-09-28")]
    [InlineData("2026-09-30T13:45:00Z", "2026-09-28")]
    [InlineData("2026-10-04T23:59:00Z", "2026-09-28")]
    [InlineData("2026-10-05T00:00:00Z", "2026-10-05")]
    public void WeekStartsOnMonday(string now, string monday)
    {
        var start = LeaderboardRules.WeekStart(DateTime.Parse(now).ToUniversalTime());
        Assert.Equal(DateTime.Parse(monday), start.Date);
    }

    private static AppDbContext CreateDb() => new(
        new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private sealed class FakeBoard : ILeaderboardReadPort
    {
        private readonly Dictionary<Guid, (string Name, double Score)> _players = [];

        public FakeBoard(params (string Name, Guid Id, double Score)[] players)
        {
            foreach (var (name, id, score) in players) _players[id] = (name, score);
        }

        public bool Unavailable { get; init; }

        public void Set(Guid id, double score) => _players[id] = (_players[id].Name, score);

        public Task<LeaderboardPool> GetPoolAsync(
            Guid viewerId, LeaderboardScope scope, LeaderboardMetric metric,
            DateTime weekStartUtc, CancellationToken ct = default) =>
            Task.FromResult(Unavailable && scope != LeaderboardScope.Global
                ? new LeaderboardPool(false, null, [])
                : new LeaderboardPool(true, null, _players
                    .Select(p => new LeaderboardCandidate(p.Key, p.Value.Name, null, 5, null, p.Value.Score))
                    .ToList()));
    }

    private sealed class RecordingCurrency : IRewardCurrencyPort
    {
        public int Coins { get; private set; }
        public int Gems { get; private set; }

        public Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default)
        {
            Coins += amount;
            return Task.CompletedTask;
        }

        public Task AddGemsAsync(Guid userId, int amount, CancellationToken ct = default)
        {
            Gems += amount;
            return Task.CompletedTask;
        }

        public Task AddTalentCrystalsAsync(Guid userId, int amount, CancellationToken ct = default) => Task.CompletedTask;
    }
}
