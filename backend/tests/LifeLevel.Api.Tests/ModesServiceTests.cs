using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Modes.Application.UseCases;
using LifeLevel.Modules.Modes.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class ModesServiceTests
{
    [Fact]
    public async Task BurnChain_BreaksAndCollectsExactlyOnce()
    {
        await using var db = CreateDb();
        var user = Guid.NewGuid();
        var history = new History();
        var money = new Money();
        var service = Service(db, history, money);
        var started = await service.StartBurnChainAsync(user);
        var start = started.StartedAt!.Value;
        history.Rows =
        [
            Row(200, start.AddHours(1)),
            Row(320, start.AddHours(2)),
            Row(300, start.AddHours(3)),
            Row(500, start.AddHours(4)),
        ];

        var ended = await service.GetBurnChainAsync(user);
        Assert.Equal("ended", ended.Phase);
        Assert.Equal(3, ended.Links.Count);
        Assert.Equal(228, ended.TotalCoins);
        Assert.Equal(1, ended.TalentCrystals);

        await service.CollectBurnChainAsync(user);
        await service.CollectBurnChainAsync(user);
        Assert.Equal(228, money.Coins);
        Assert.Equal(1, money.Crystals);
        Assert.Single(db.Set<ModeRewardSettlement>());
    }

    [Fact]
    public async Task Delve_SafeFullClear_PaysCoinsAndTwoCrystals()
    {
        await using var db = CreateDb();
        var user = Guid.NewGuid();
        var history = new History
        {
            Rows = [new ActivityRecordDto(Guid.NewGuid(), "Gym", 45, 0, 200, DateTime.UtcNow)]
        };
        var money = new Money();
        var service = Service(db, history, money);
        var run = await service.StartDelveAsync(user);

        for (var room = 0; room < 5; room++)
        {
            run = await service.ChooseDelvePathAsync(user, run.Id, "safe");
            run = await service.AttemptDelveAsync(user, run.Id);
            if (room < 4) run = await service.ContinueDelveAsync(user, run.Id);
        }

        Assert.Equal("result", run.Phase);
        Assert.Equal("cleared", run.EndReason);
        Assert.Equal(5, run.RoomsCleared);
        Assert.Equal(2, run.TalentCrystals);
        Assert.Equal(run.Payout, money.Coins);
        Assert.Equal(2, money.Crystals);
    }

    [Fact]
    public async Task Delve_DailyEntriesUseUtcAndCapAtThree()
    {
        await using var db = CreateDb();
        var user = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var history = new History
        {
            Rows =
            [
                new(Guid.NewGuid(), "Running", 45, 0, 0, now),
                new(Guid.NewGuid(), "Gym", 45, 0, 0, now),
            ]
        };
        var service = Service(db, history, new Money());
        var status = await service.GetTreasureDelveAsync(user);
        Assert.Equal(3, status.RunsEarned);
        Assert.Equal(3, status.RunsLeft);
        Assert.Equal(new DateTime(now.Year, now.Month, now.Day, 0, 0, 0, DateTimeKind.Utc).AddDays(1), status.ResetAtUtc);
    }

    private static ModesService Service(AppDbContext db, History history, Money money) =>
        new(db, history, new Stats(), new Items(), money, new Profile());

    private static ActivityRecordDto Row(int calories, DateTime at) =>
        new(Guid.NewGuid(), "Running", 30, 5, calories, at);

    private static AppDbContext CreateDb() => new(
        new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private sealed class History : IActivityHistoryReadPort
    {
        public IReadOnlyList<ActivityRecordDto> Rows { get; set; } = [];
        public Task<IReadOnlyList<ActivityRecordDto>> ListForUserBetweenAsync(Guid userId, DateTime fromUtc, DateTime toUtc, CancellationToken ct = default) => Task.FromResult(Rows);
    }

    private sealed class Stats : ICharacterStatsSnapshotReadPort
    {
        public Task<CharacterStatsSnapshot?> GetStatsAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult<CharacterStatsSnapshot?>(new(10, 20, 20, 20, 20, 20));
    }

    private sealed class Items : IChestItemRewardPort
    {
        public Task<ChestItemGrant?> GrantRandomUnownedAsync(Guid userId, string rarity, CancellationToken ct = default) => Task.FromResult<ChestItemGrant?>(null);
    }

    private sealed class Money : IRewardCurrencyPort
    {
        public int Coins { get; private set; }
        public int Crystals { get; private set; }
        public Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default) { Coins += amount; return Task.CompletedTask; }
        public Task AddGemsAsync(Guid userId, int amount, CancellationToken ct = default) => Task.CompletedTask;
        public Task AddTalentCrystalsAsync(Guid userId, int amount, CancellationToken ct = default) { Crystals += amount; return Task.CompletedTask; }
    }

    private sealed class Profile : ITalentProfileReadPort
    {
        public Task<TalentSummaryDto> GetSummaryAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(TalentSummaryDto.Empty);
    }
}
