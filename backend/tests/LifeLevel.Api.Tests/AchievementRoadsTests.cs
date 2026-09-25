using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Achievements.Application.DTOs;
using LifeLevel.Modules.Achievements.Application.UseCases;
using LifeLevel.Modules.Achievements.Domain.Entities;
using LifeLevel.Modules.Achievements.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class AchievementRoadsTests
{
    private static readonly Guid User = Guid.NewGuid();

    [Fact]
    public async Task Roads_GroupByCategoryAndTier_AndReportReadyAndChests()
    {
        await using var db = Db();
        var (common, uncommonA, uncommonB, _) = Seed(db);
        Unlock(db, common, claimed: true);
        Unlock(db, uncommonA, claimed: false);
        await db.SaveChangesAsync();
        var (service, _, _, _) = Service(db);

        var roads = await service.GetRoadsAsync(User);

        var running = Assert.Single(roads.Roads);
        Assert.Equal("Running", running.Category);
        Assert.Equal(["Common", "Uncommon", "Rare"], running.Stages.Select(s => s.Tier));
        Assert.True(running.Stages[0].ChestReady);
        Assert.Equal(1, running.Stages[1].Ready);
        Assert.Equal(0, running.CurrentStage);
        Assert.Equal(1, roads.ReadyCount);
        Assert.Equal(1, roads.ChestsReady);
        Assert.Equal(150, running.Stages[1].Achievements.First(a => a.Id == uncommonA).CoinReward);
    }

    [Fact]
    public async Task Claim_PaysXpCoinsGemsOnce_AndReportsFinishedStage()
    {
        await using var db = Db();
        var (common, _, _, _) = Seed(db);
        Unlock(db, common, claimed: false);
        await db.SaveChangesAsync();
        var (service, xp, currency, _) = Service(db);

        var first = await service.ClaimAsync(User, [common]);
        var second = await service.ClaimAsync(User, [common]);

        Assert.Equal([common], first.ClaimedIds);
        Assert.Equal(100, first.Xp);
        Assert.Equal(50, first.Coins);
        Assert.Equal(1, first.Gems);
        Assert.Equal(new AchievementStageKeyDto("Running", "Common"), Assert.Single(first.ChestsReady));
        Assert.Empty(second.ClaimedIds);
        Assert.Equal(100, xp.Total);
        Assert.Equal(50, currency.Coins);
        Assert.Equal(1, currency.Gems);
    }

    [Fact]
    public async Task Claim_IgnoresLockedAchievements()
    {
        await using var db = Db();
        var (_, uncommonA, _, _) = Seed(db);
        db.UserAchievements.Add(new UserAchievement { UserId = User, AchievementId = uncommonA, CurrentValue = 3 });
        await db.SaveChangesAsync();
        var (service, xp, _, _) = Service(db);

        var result = await service.ClaimAsync(User, [uncommonA]);

        Assert.Empty(result.ClaimedIds);
        Assert.Equal(0, xp.Total);
    }

    [Fact]
    public async Task ClaimAll_ClaimsEveryReady_AndStageChestWaitsForTheWholeStage()
    {
        await using var db = Db();
        var (common, uncommonA, uncommonB, _) = Seed(db);
        Unlock(db, common, claimed: false);
        Unlock(db, uncommonA, claimed: false);
        await db.SaveChangesAsync();
        var (service, _, currency, _) = Service(db);

        var result = await service.ClaimAllAsync(User, "running");

        Assert.Equal(2, result.ClaimedIds.Count);
        Assert.Equal(50 + 150, currency.Coins);
        // Uncommon still has uncommonB locked → only the Common chest is ready.
        Assert.Equal(["Common"], result.ChestsReady.Select(c => c.Tier));
        var ex = await Assert.ThrowsAsync<AchievementException>(() => service.OpenStageChestAsync(User, "Running", "Uncommon"));
        Assert.Equal("stage_not_complete", ex.Code);
        _ = uncommonB;
    }

    [Fact]
    public async Task OpenStageChest_GrantsItemOfChestRarityAndBonus_Once()
    {
        await using var db = Db();
        var (common, _, _, _) = Seed(db);
        Unlock(db, common, claimed: true);
        await db.SaveChangesAsync();
        var (service, _, currency, items) = Service(db);

        var opened = await service.OpenStageChestAsync(User, "Running", "Common");

        Assert.Equal("wayfarer", opened.ChestKey);
        Assert.Equal("Common", items.LastRarity);
        Assert.NotNull(opened.Item);
        Assert.Equal(200, opened.Coins);
        Assert.Equal(2, opened.Gems);
        Assert.Equal(200, currency.Coins);
        var ex = await Assert.ThrowsAsync<AchievementException>(() => service.OpenStageChestAsync(User, "Running", "Common"));
        Assert.Equal("chest_already_opened", ex.Code);

        var roads = await service.GetRoadsAsync(User);
        var stage = roads.Roads[0].Stages[0];
        Assert.True(stage.ChestOpened);
        Assert.False(stage.ChestReady);
        Assert.Equal(1, roads.Roads[0].CurrentStage);
    }

    [Fact]
    public async Task OpenStageChest_WhenNoItemLeft_StillPaysBonus()
    {
        await using var db = Db();
        var (common, _, _, _) = Seed(db);
        Unlock(db, common, claimed: true);
        await db.SaveChangesAsync();
        var (service, _, currency, items) = Service(db);
        items.Exhausted = true;

        var opened = await service.OpenStageChestAsync(User, "Running", "Common");

        Assert.Null(opened.Item);
        Assert.Equal(200, currency.Coins);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static AppDbContext Db() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static (Guid Common, Guid UncommonA, Guid UncommonB, Guid Rare) Seed(AppDbContext db)
    {
        Achievement A(AchievementTier tier, string title, double target, long xp, int coins, int gems) => new()
        {
            Id = Guid.NewGuid(), Title = title, Icon = "🏃", Category = AchievementCategory.Running,
            Tier = tier, XpReward = xp, CoinReward = coins, GemReward = gems,
            ConditionType = ConditionType.TotalActivities, TargetValue = target, TargetUnit = "activities",
        };
        var common = A(AchievementTier.Common, "First Steps", 1, 100, 50, 1);
        var uncommonA = A(AchievementTier.Uncommon, "Road Warrior", 10, 250, 150, 3);
        var uncommonB = A(AchievementTier.Uncommon, "Consistent Mover", 12, 300, 150, 3);
        var rare = A(AchievementTier.Rare, "Marathon Prep", 42, 500, 400, 8);
        db.Achievements.AddRange(common, uncommonA, uncommonB, rare);
        return (common.Id, uncommonA.Id, uncommonB.Id, rare.Id);
    }

    private static void Unlock(AppDbContext db, Guid achievementId, bool claimed)
    {
        var at = DateTime.UtcNow.AddDays(-1);
        db.UserAchievements.Add(new UserAchievement
        {
            UserId = User, AchievementId = achievementId, CurrentValue = 99,
            UnlockedAt = at, ClaimedAt = claimed ? at : null,
        });
    }

    // No character → CheckUnlocks leaves the seeded progress alone.
    private static (AchievementService, Xp, Currency, ChestItems) Service(AppDbContext db)
    {
        var xp = new Xp();
        var currency = new Currency();
        var items = new ChestItems();
        return (new AchievementService(db, xp, new StubCharacterIdReadPort(), currency, currency, items), xp, currency, items);
    }

    private sealed class Xp : ICharacterXpPort
    {
        public long Total { get; private set; }
        public Task<XpAwardResult> AwardXpAsync(Guid userId, string source, string sourceEmoji,
            string description, long xp, CancellationToken ct = default)
        {
            Total += xp;
            return Task.FromResult(XpAwardResult.None);
        }
    }

    private sealed class Currency : IRewardCurrencyPort, IShopWalletPort
    {
        public long Coins { get; private set; }
        public int Gems { get; private set; }
        public Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default) { Coins += amount; return Task.CompletedTask; }
        public Task AddCrystalsAsync(Guid userId, int amount, CancellationToken ct = default) { Gems += amount; return Task.CompletedTask; }
        public Task<ShopWalletBalance> GetBalanceAsync(Guid userId, CancellationToken ct = default) => Task.FromResult(new ShopWalletBalance(Coins, Gems));
        public Task<bool> TrySpendAsync(Guid userId, ShopCurrency currency, int amount, CancellationToken ct = default) => Task.FromResult(false);
    }

    private sealed class ChestItems : IChestItemRewardPort
    {
        public string? LastRarity { get; private set; }
        public bool Exhausted { get; set; }
        public Task<ChestItemGrant?> GrantRandomUnownedAsync(Guid userId, string rarity, CancellationToken ct = default)
        {
            LastRarity = rarity;
            return Task.FromResult(Exhausted ? null : new ChestItemGrant(Guid.NewGuid(), "Recovery Slides", "🩴", rarity, null));
        }
    }
}
