using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Talents.Application.UseCases;
using LifeLevel.Modules.Talents.Domain;
using LifeLevel.Modules.Talents.Domain.Entities;
using LifeLevel.Modules.Talents.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class TalentProgressiveDrawCostTests
{
    [Theory]
    [InlineData(0, 300, 1)]
    [InlineData(10, 985, 2)]
    [InlineData(20, 1675, 4)]
    [InlineData(40, 3055, 8)]
    [InlineData(60, 4440, 12)]
    [InlineData(80, 5840, 18)]
    [InlineData(100, 7250, 25)]
    [InlineData(120, 8675, 35)]
    [InlineData(140, 10125, 48)]
    public void DrawCost_UsesSuccessfulDrawCurve(int completedDraws, int coins, int crystals)
    {
        Assert.Equal(coins, TalentEconomy.DrawCoinCost(completedDraws));
        Assert.Equal(crystals, TalentEconomy.DrawCrystalCost(completedDraws));
    }

    [Fact]
    public void CoinCost_IncreasesAfterEverySuccessfulDraw()
    {
        var previous = TalentEconomy.DrawCoinCost(0);
        for (var draws = 1; draws <= 500; draws++)
        {
            var current = TalentEconomy.DrawCoinCost(draws);
            Assert.True(current > previous, $"Expected draw {draws + 1} to cost more than draw {draws}.");
            previous = current;
        }
    }

    [Fact]
    public async Task GetScreen_DerivesPriceFromSuccessfulDrawHistory()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var talent = Talent("active", maxLevel: 30, active: true);
        db.Add(talent);
        db.Add(Wallet(userId, 10_000, 100));
        for (var draw = 1; draw <= 20; draw++) db.Add(DrawEntry(userId, talent.Id, draw));
        await db.SaveChangesAsync();

        var screen = await new TalentService(db).GetScreenAsync(userId);

        Assert.Equal(20, screen.DrawCount);
        Assert.Equal(1675, screen.DrawCoinCost);
        Assert.Equal(4, screen.DrawCrystalCost);
        Assert.False(screen.CollectionComplete);
        Assert.True(screen.CanDraw);
    }

    [Fact]
    public async Task Draw_DebitsCurrentPriceAndRecordsOneBasedDrawNumber()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var talent = Talent("drawn", maxLevel: 30, active: true);
        db.Add(talent);
        db.Add(UserTalent(userId, talent.Id, 1));
        db.Add(Wallet(userId, 2_000, 10));
        db.Add(DrawEntry(userId, talent.Id, 1));
        await db.SaveChangesAsync();

        var result = await new TalentService(db).DrawAsync(userId);
        var wallet = await db.Set<UserTalentWallet>().SingleAsync();
        var audit = await db.Set<TalentDrawEntry>().OrderByDescending(x => x.DrawNumber).FirstAsync();

        Assert.False(result.IsNew);
        Assert.Equal(2, result.Talent.Level);
        Assert.Equal(1630, wallet.Coins);
        Assert.Equal(9, wallet.Crystals);
        Assert.Equal(2, audit.DrawNumber);
        Assert.Equal(370, audit.CoinsSpent);
        Assert.Equal(1, audit.CrystalsSpent);
    }

    [Fact]
    public async Task FailedDraw_DoesNotAdvancePriceOrCreateAuditEntry()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var talent = Talent("drawn", maxLevel: 30, active: true);
        db.Add(talent);
        db.Add(Wallet(userId, 299, 1));
        await db.SaveChangesAsync();

        await Assert.ThrowsAsync<InvalidOperationException>(() => new TalentService(db).DrawAsync(userId));
        var screen = await new TalentService(db).GetScreenAsync(userId);

        Assert.Equal(0, screen.DrawCount);
        Assert.Equal(300, screen.DrawCoinCost);
        Assert.Empty(await db.Set<TalentDrawEntry>().ToListAsync());
    }

    [Fact]
    public async Task Draw_WhenCollectionIsComplete_DoesNotSpendCurrency()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var talent = Talent("complete", maxLevel: 10, active: true);
        db.Add(talent);
        db.Add(UserTalent(userId, talent.Id, 10));
        db.Add(Wallet(userId, 1_000, 10));
        await db.SaveChangesAsync();

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() => new TalentService(db).DrawAsync(userId));
        var wallet = await db.Set<UserTalentWallet>().SingleAsync();

        Assert.Equal("Your talent collection is complete.", error.Message);
        Assert.Equal(1_000, wallet.Coins);
        Assert.Equal(10, wallet.Crystals);
        Assert.Empty(await db.Set<TalentDrawEntry>().ToListAsync());
    }

    private static AppDbContext CreateDb() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static Talent Talent(string key, int maxLevel, bool active) => new()
    {
        Id = Guid.NewGuid(), Key = key, Name = key, Description = key, IconKey = "stat_strength",
        Rarity = TalentRarity.Common, EffectType = TalentEffectType.StatStrength, PerLevelValue = 1,
        MaxLevel = maxLevel, DrawWeight = 100, IsActive = active,
    };

    private static UserTalent UserTalent(Guid userId, Guid talentId, int level) => new()
        { UserId = userId, TalentId = talentId, Level = level };

    private static UserTalentWallet Wallet(Guid userId, long coins, int crystals) => new()
        { UserId = userId, Coins = coins, Crystals = crystals };

    private static TalentDrawEntry DrawEntry(Guid userId, Guid talentId, int drawNumber) => new()
    {
        UserId = userId, TalentId = talentId, DrawNumber = drawNumber, Kind = TalentDrawKind.Duplicate,
        CoinsSpent = TalentEconomy.DrawCoinCost(drawNumber - 1),
        CrystalsSpent = TalentEconomy.DrawCrystalCost(drawNumber - 1),
    };
}
