using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Api.Tests;

file sealed class RegionChestWallet : IRewardCurrencyPort, IShopWalletPort
{
    public long Coins { get; private set; }
    public int Gems { get; private set; }

    public Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default)
    { Coins += amount; return Task.CompletedTask; }
    public Task AddGemsAsync(Guid userId, int amount, CancellationToken ct = default)
    { Gems += amount; return Task.CompletedTask; }
    public Task AddTalentCrystalsAsync(Guid userId, int amount, CancellationToken ct = default) => Task.CompletedTask;
    public Task<ShopWalletBalance> GetBalanceAsync(Guid userId, CancellationToken ct = default) =>
        Task.FromResult(new ShopWalletBalance(Coins, Gems));
    public Task<bool> TrySpendAsync(Guid userId, ShopCurrency currency, int amount, CancellationToken ct = default) =>
        Task.FromResult(false);
}

file sealed class RegionChestLevel(int level = 99) : ICharacterLevelReadPort
{
    public Task<int> GetLevelAsync(Guid userId, CancellationToken ct = default) => Task.FromResult(level);
}

public class RegionChestServiceTests
{
    private static AppDbContext CreateDb(string name) => new(
        new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(name).Options);

    private static async Task<(Guid UserId, Region Region, UserBossState State)> SeedAsync(
        AppDbContext db, int chapter, bool defeated = false, bool expired = false)
    {
        var world = new World { Id = Guid.NewGuid(), Name = "Test", IsActive = true };
        var region = new Region
        {
            Id = Guid.NewGuid(), WorldId = world.Id, World = world, Name = "Branching Region",
            Emoji = "🌲", Theme = RegionTheme.Forest, ChapterIndex = chapter,
            LevelRequirement = 1, Lore = "Test", BossName = "Boss",
        };
        var bossZone = new WorldZoneEntity
        {
            Id = Guid.NewGuid(), RegionId = region.Id, Region = region, Name = "Boss",
            Emoji = "💀", Type = WorldZoneType.Boss, IsBoss = true, Tier = 10,
        };
        var boss = new Boss
        {
            Id = Guid.NewGuid(), Name = "Boss", Icon = "💀", MaxHp = 100,
            WorldZoneId = bossZone.Id, SuppressExpiry = true,
        };
        var userId = Guid.NewGuid();
        var state = new UserBossState
        {
            Id = Guid.NewGuid(), UserId = userId, BossId = boss.Id, Boss = boss,
            IsDefeated = defeated, IsExpired = expired,
        };
        db.AddRange(world, region, bossZone, boss, state);
        await db.SaveChangesAsync();
        return (userId, region, state);
    }

    [Theory]
    [InlineData(true, false)]
    [InlineData(false, true)]
    public async Task ResolvedBoss_IsRetroactivelyReady(bool defeated, bool expired)
    {
        await using var db = CreateDb($"ready-{defeated}-{expired}");
        var setup = await SeedAsync(db, 1, defeated, expired);
        var wallet = new RegionChestWallet();

        var result = await new RegionChestService(db, wallet, wallet, new RegionChestLevel())
            .GetAsync(setup.UserId);

        Assert.Equal("ready", Assert.Single(result.Regions).Status);
    }

    [Fact]
    public async Task Claim_PaysTierRewardOnce_AndReturnsWallet()
    {
        await using var db = CreateDb(nameof(Claim_PaysTierRewardOnce_AndReturnsWallet));
        var setup = await SeedAsync(db, 8, defeated: true);
        var wallet = new RegionChestWallet();
        var service = new RegionChestService(db, wallet, wallet, new RegionChestLevel());

        var result = await service.ClaimAsync(setup.UserId, setup.Region.Id);

        Assert.Equal(500, result.Coins);
        Assert.Equal(50, result.Gems);
        Assert.Equal(500, result.Wallet.Coins);
        Assert.Equal(50, result.Wallet.Gems);
        Assert.Single(db.UserRegionChestClaims);
        var ex = await Assert.ThrowsAsync<RegionChestException>(
            () => service.ClaimAsync(setup.UserId, setup.Region.Id));
        Assert.Equal("already_claimed", ex.Code);
        Assert.Equal(500, wallet.Coins);
        Assert.Equal(50, wallet.Gems);
    }

    [Fact]
    public async Task FirstCompletedRegion_PaysTheExistingFirstChestReward()
    {
        await using var db = CreateDb(nameof(FirstCompletedRegion_PaysTheExistingFirstChestReward));
        var setup = await SeedAsync(db, 1, defeated: true);
        var wallet = new RegionChestWallet();

        var result = await new RegionChestService(db, wallet, wallet, new RegionChestLevel(1))
            .ClaimAsync(setup.UserId, setup.Region.Id);

        Assert.Equal(150, result.Coins);
        Assert.Equal(20, result.Gems);
    }

    [Fact]
    public async Task UnresolvedBoss_CannotBeClaimed()
    {
        await using var db = CreateDb(nameof(UnresolvedBoss_CannotBeClaimed));
        var setup = await SeedAsync(db, 1);
        var wallet = new RegionChestWallet();

        var ex = await Assert.ThrowsAsync<RegionChestException>(
            () => new RegionChestService(db, wallet, wallet, new RegionChestLevel())
                .ClaimAsync(setup.UserId, setup.Region.Id));

        Assert.Equal("not_ready", ex.Code);
        Assert.Empty(db.UserRegionChestClaims);
    }
}
