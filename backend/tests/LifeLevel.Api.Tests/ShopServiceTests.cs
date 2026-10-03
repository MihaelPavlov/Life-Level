using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class ShopServiceTests
{
    [Fact]
    public async Task DailyRotation_IsShared_AndHasThreeOffersPerCurrency()
    {
        await using var db = Db();
        SeedCatalog(db);
        await db.SaveChangesAsync();
        var wallet = new Wallet();
        var service = Service(db, wallet);

        var first = await service.GetAsync(Guid.NewGuid());
        var second = await service.GetAsync(Guid.NewGuid());

        Assert.Equal(first.DailyOffers.Select(x => x.Item.Id), second.DailyOffers.Select(x => x.Item.Id));
        Assert.Equal(3, first.DailyOffers.Count(x => x.Currency == ShopCurrency.Coins));
        Assert.Equal(3, first.DailyOffers.Count(x => x.Currency == ShopCurrency.Gems));
    }

    [Fact]
    public async Task Purchase_DeductsCurrency_GrantsOnce_AndIsIdempotent()
    {
        await using var db = Db();
        SeedCatalog(db);
        await db.SaveChangesAsync();
        var wallet = new Wallet();
        var service = Service(db, wallet);
        var user = Guid.NewGuid();
        var offer = (await service.GetAsync(user)).DailyOffers.First(x => x.Currency == ShopCurrency.Coins);
        var request = Guid.NewGuid();

        await service.PurchaseItemAsync(user, offer.Item.Id, request);
        await service.PurchaseItemAsync(user, offer.Item.Id, request);

        Assert.Equal(10_000 - offer.Price, wallet.Coins);
        Assert.Single(await db.CharacterItems.ToListAsync());
        Assert.Single(await db.ShopPurchases.ToListAsync());
    }

    [Fact]
    public async Task EquippedCatalogAlias_IsOwned_AndCannotBePurchasedAgain()
    {
        await using var db = Db();
        SeedCatalog(db);
        await db.SaveChangesAsync();
        var wallet = new Wallet();
        var service = Service(db, wallet);
        var user = Guid.NewGuid();
        var offer = (await service.GetAsync(user)).DailyOffers.First(x => x.Currency == ShopCurrency.Coins);
        var alias = new Item
        {
            Id = Guid.NewGuid(), Name = offer.Item.Name, Description = "Older catalog entry",
            Icon = "x", Rarity = Enum.Parse<ItemRarity>(offer.Item.Rarity),
            Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest
        };
        db.Items.Add(alias);
        db.CharacterItems.Add(new CharacterItem
        {
            Id = Guid.NewGuid(), CharacterId = CharacterId, ItemId = alias.Id, IsEquipped = true
        });
        await db.SaveChangesAsync();

        var ownedOffer = (await service.GetAsync(user)).DailyOffers.Single(x => x.Item.Id == offer.Item.Id);
        Assert.True(ownedOffer.Owned);
        Assert.False(ownedOffer.CanPurchase);
        var error = await Assert.ThrowsAsync<ShopException>(() =>
            service.PurchaseItemAsync(user, offer.Item.Id, Guid.NewGuid()));
        Assert.Equal("already_owned", error.Code);
        Assert.Equal(10_000, wallet.Coins);
        Assert.Single(await db.CharacterItems.ToListAsync());
    }

    [Fact]
    public async Task Chest_NeverReturnsOwnedItemOfRequestedRarity()
    {
        await using var db = Db();
        SeedCatalog(db);
        db.CharacterItems.Add(new CharacterItem { Id = Guid.NewGuid(), CharacterId = CharacterId, ItemId = Id(10) });
        await db.SaveChangesAsync();
        var service = Service(db, new Wallet());

        var result = await service.PurchaseChestAsync(Guid.NewGuid(), "wayfarer", Guid.NewGuid());

        Assert.NotEqual(Id(10), result.GrantedItem.Id);
        Assert.Equal("Common", result.GrantedItem.Rarity);
    }

    [Fact]
    public async Task RewardGrant_DoesNotAddAnOwnedCatalogAlias()
    {
        await using var db = Db();
        SeedCatalog(db);
        var alias = new Item
        {
            Id = Guid.NewGuid(), Name = "Item 33", Description = "Older catalog entry",
            Icon = "x", Rarity = ItemRarity.Uncommon,
            Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest
        };
        db.Items.Add(alias);
        db.CharacterItems.Add(new CharacterItem
        {
            Id = Guid.NewGuid(), CharacterId = CharacterId, ItemId = alias.Id, IsEquipped = true
        });
        await db.SaveChangesAsync();

        var grant = new ItemGrantService(db, new StubCharacterIdReadPort(CharacterId), new Slots());
        var result = await grant.GrantItemAsync(Guid.NewGuid(), Id(33));

        Assert.False(result.WasNew);
        Assert.False(result.InventoryFull);
        Assert.Equal(alias.Id, result.Item?.ItemId);
        Assert.Single(await db.CharacterItems.ToListAsync());
    }

    private static readonly Guid CharacterId = Guid.NewGuid();
    private static AppDbContext Db() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
    private static ShopService Service(AppDbContext db, Wallet wallet) => new(db, wallet,
        new StubCharacterIdReadPort(CharacterId), new Slots());
    private static Guid Id(int suffix) => Guid.Parse($"10000000-0000-0000-0000-{suffix:000000000000}");

    private static void SeedCatalog(AppDbContext db)
    {
        var rows = new (int Id, ItemRarity Rarity)[] {
            (10, ItemRarity.Common), (12, ItemRarity.Epic), (14, ItemRarity.Legendary),
            (2, ItemRarity.Epic), (16, ItemRarity.Common), (17, ItemRarity.Legendary),
            (19, ItemRarity.Common), (29, ItemRarity.Rare), (30, ItemRarity.Uncommon),
            (31, ItemRarity.Epic), (32, ItemRarity.Rare), (33, ItemRarity.Uncommon),
            (34, ItemRarity.Epic), (35, ItemRarity.Uncommon), (36, ItemRarity.Rare),
        };
        db.Items.AddRange(rows.Select(x => new Item { Id = Id(x.Id), Name = $"Item {x.Id}",
            Description = "Test", Icon = "x", Rarity = x.Rarity,
            Category = ItemCategory.Clothing, SlotType = EquipmentSlotType.Chest }));
    }

    private sealed class Slots : IInventorySlotReadPort
    {
        public Task<int> GetMaxInventorySlotsAsync(Guid userId, CancellationToken ct = default) => Task.FromResult(50);
    }
    private sealed class Wallet : IShopWalletPort
    {
        public long Coins { get; private set; } = 10_000;
        public int Gems { get; private set; } = 10_000;
        public Task<ShopWalletBalance> GetBalanceAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(new ShopWalletBalance(Coins, Gems));
        public Task<bool> TrySpendAsync(Guid userId, ShopCurrency currency, int amount, CancellationToken ct = default)
        {
            if (currency == ShopCurrency.Coins) { if (Coins < amount) return Task.FromResult(false); Coins -= amount; }
            else { if (Gems < amount) return Task.FromResult(false); Gems -= amount; }
            return Task.FromResult(true);
        }
    }
}
