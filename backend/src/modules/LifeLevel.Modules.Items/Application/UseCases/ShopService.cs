using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using LifeLevel.Modules.Items.Application.DTOs;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace LifeLevel.Modules.Items.Application.UseCases;

public class ShopService(
    DbContext db,
    IShopWalletPort wallet,
    ICharacterIdReadPort characterIds,
    IInventorySlotReadPort inventorySlots)
{
    public const int RefreshCostCoins = 500;

    private static readonly List<Guid> Pool =
    [
        Id(10), Id(12), Id(14), Id(2), Id(16), Id(17), Id(19), Id(29), Id(30),
        Id(31), Id(32), Id(33), Id(34), Id(35), Id(36),
    ];

    /// <summary>Items a chest can draw from (Shop chests and achievement stage chests).</summary>
    public static IReadOnlyList<Guid> ChestPool => Pool;

    private static readonly Dictionary<ItemRarity, (ShopCurrency Currency, int Price)> Prices = new()
    {
        [ItemRarity.Common] = (ShopCurrency.Coins, 150),
        [ItemRarity.Uncommon] = (ShopCurrency.Coins, 320),
        [ItemRarity.Rare] = (ShopCurrency.Coins, 900),
        [ItemRarity.Epic] = (ShopCurrency.Gems, 80),
        [ItemRarity.Legendary] = (ShopCurrency.Gems, 220),
    };

    private static readonly (string Key, string Name, ItemRarity Rarity, ShopCurrency Currency, int Price)[] Chests =
    [
        ("wayfarer", "Wayfarer Chest", ItemRarity.Common, ShopCurrency.Coins, 500),
        ("adept", "Adept Chest", ItemRarity.Rare, ShopCurrency.Gems, 120),
        ("champion", "Champion Chest", ItemRarity.Legendary, ShopCurrency.Gems, 450),
    ];

    public async Task<ShopResponse> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var day = DateTime.UtcNow.Date;
        var characterId = await characterIds.GetCharacterIdAsync(userId, ct)
            ?? throw new ShopException("character_not_found", "Create a character before using the shop.");
        var maxSlots = await inventorySlots.GetMaxInventorySlotsAsync(userId, ct);
        var ownedIds = await db.Set<CharacterItem>().Where(x => x.CharacterId == characterId)
            .Select(x => x.ItemId).ToHashSetAsync(ct);
        var catalog = await db.Set<Item>().Where(x => Pool.Contains(x.Id)).ToListAsync(ct);
        var balance = await wallet.GetBalanceAsync(userId, ct);
        var state = await db.Set<UserShopDailyState>()
            .FirstOrDefaultAsync(x => x.UserId == userId && x.RotationDateUtc == day, ct);
        var offerIds = state is null ? GlobalRotation(catalog, day) : ParseIds(state.ItemIdsJson);
        var inventoryCount = ownedIds.Count;
        var full = inventoryCount >= maxSlots;

        var offers = offerIds.Select(id => catalog.FirstOrDefault(x => x.Id == id)).Where(x => x != null)
            .Select(item =>
            {
                var owned = ownedIds.Contains(item!.Id);
                var price = Prices[item.Rarity];
                var enough = price.Currency == ShopCurrency.Coins ? balance.Coins >= price.Price : balance.Gems >= price.Price;
                var reason = owned ? "Owned" : full ? "Inventory full" : !enough ? $"Not enough {Label(price.Currency)}" : null;
                return new ShopOfferDto(ToDto(item), price.Currency, price.Price, owned, reason is null, reason);
            }).ToList();

        var chestViews = Chests.Select(chest =>
        {
            var remaining = catalog.Count(x => x.Rarity == chest.Rarity && !ownedIds.Contains(x.Id));
            var enough = chest.Currency == ShopCurrency.Coins ? balance.Coins >= chest.Price : balance.Gems >= chest.Price;
            var reason = remaining == 0 ? "All rewards owned" : full ? "Inventory full" : !enough ? $"Not enough {Label(chest.Currency)}" : null;
            return new ShopChestDto(chest.Key, chest.Name, chest.Rarity.ToString(), chest.Currency,
                chest.Price, remaining, reason is null, reason);
        }).ToList();

        var canRefresh = state is null && balance.Coins >= RefreshCostCoins &&
            CanBuildRefresh(catalog, ownedIds, offerIds);
        var refreshReason = state is not null ? "Already refreshed today"
            : balance.Coins < RefreshCostCoins ? "Not enough Coins"
            : !CanBuildRefresh(catalog, ownedIds, offerIds) ? "Not enough replacement gear" : null;

        return new ShopResponse(new ShopWalletDto(balance.Coins, balance.Gems), day.AddDays(1),
            new ShopRefreshDto(RefreshCostCoins, canRefresh, state is not null, refreshReason), offers,
            chestViews, inventoryCount, maxSlots);
    }

    public async Task<ShopResponse> RefreshAsync(Guid userId, CancellationToken ct = default)
    {
        await using var tx = await BeginTransactionAsync(ct);
        var day = DateTime.UtcNow.Date;
        if (await db.Set<UserShopDailyState>().AnyAsync(x => x.UserId == userId && x.RotationDateUtc == day, ct))
            throw new ShopException("already_refreshed", "The Daily Shop has already been refreshed today.");

        var characterId = await RequireCharacterAsync(userId, ct);
        var owned = await db.Set<CharacterItem>().Where(x => x.CharacterId == characterId)
            .Select(x => x.ItemId).ToHashSetAsync(ct);
        var catalog = await db.Set<Item>().Where(x => Pool.Contains(x.Id)).ToListAsync(ct);
        var current = GlobalRotation(catalog, day);
        var replacement = BuildRefresh(catalog, owned, current, userId, day);
        if (replacement.Count != 6)
            throw new ShopException("refresh_unavailable", "There is not enough unowned replacement gear to refresh the shop.");
        if (!await wallet.TrySpendAsync(userId, ShopCurrency.Coins, RefreshCostCoins, ct))
            throw new ShopException("insufficient_currency", "You need 500 Coins to refresh the shop.");

        db.Set<UserShopDailyState>().Add(new UserShopDailyState
        {
            Id = Guid.NewGuid(), UserId = userId, RotationDateUtc = day,
            ItemIdsJson = JsonSerializer.Serialize(replacement), RefreshedAtUtc = DateTime.UtcNow,
        });
        await db.SaveChangesAsync(ct);
        if (tx != null) await tx.CommitAsync(ct);
        return await GetAsync(userId, ct);
    }

    public async Task<ShopPurchaseResult> PurchaseItemAsync(
        Guid userId, Guid itemId, Guid clientPurchaseId, CancellationToken ct = default)
    {
        return await PurchaseAsync(userId, clientPurchaseId, $"item:{itemId}", async (characterId, owned, catalog) =>
        {
            var day = DateTime.UtcNow.Date;
            var state = await db.Set<UserShopDailyState>()
                .FirstOrDefaultAsync(x => x.UserId == userId && x.RotationDateUtc == day, ct);
            var available = state is null ? GlobalRotation(catalog, day) : ParseIds(state.ItemIdsJson);
            if (!available.Contains(itemId)) throw new ShopException("offer_not_available", "That offer is no longer available.");
            var item = catalog.FirstOrDefault(x => x.Id == itemId)
                ?? throw new ShopException("offer_not_available", "That offer is no longer available.");
            var price = Prices[item.Rarity];
            return (item, price.Currency, price.Price);
        }, ct);
    }

    public async Task<ShopPurchaseResult> PurchaseChestAsync(
        Guid userId, string tier, Guid clientPurchaseId, CancellationToken ct = default)
    {
        var chest = Chests.FirstOrDefault(x => x.Key.Equals(tier, StringComparison.OrdinalIgnoreCase));
        if (chest == default) throw new ShopException("chest_not_found", "That chest does not exist.");
        return await PurchaseAsync(userId, clientPurchaseId, $"chest:{chest.Key}", (_, owned, catalog) =>
        {
            var candidates = catalog.Where(x => x.Rarity == chest.Rarity && !owned.Contains(x.Id)).ToList();
            if (candidates.Count == 0) throw new ShopException("chest_exhausted", "You already own every reward in this chest.");
            var item = candidates[RandomNumberGenerator.GetInt32(candidates.Count)];
            return Task.FromResult((item, chest.Currency, chest.Price));
        }, ct);
    }

    private async Task<ShopPurchaseResult> PurchaseAsync(Guid userId, Guid clientPurchaseId, string offerKey,
        Func<Guid, HashSet<Guid>, List<Item>, Task<(Item Item, ShopCurrency Currency, int Price)>> resolve,
        CancellationToken ct)
    {
        if (clientPurchaseId == Guid.Empty) throw new ShopException("invalid_request", "A purchase id is required.");
        await using var tx = await BeginTransactionAsync(ct);
        var previous = await db.Set<ShopPurchase>().FirstOrDefaultAsync(
            x => x.UserId == userId && x.ClientPurchaseId == clientPurchaseId, ct);
        if (previous != null)
        {
            var previousItem = await db.Set<Item>().SingleAsync(x => x.Id == previous.GrantedItemId, ct);
            if (tx != null) await tx.CommitAsync(ct);
            return new ShopPurchaseResult(await GetAsync(userId, ct), ToDto(previousItem));
        }

        var characterId = await RequireCharacterAsync(userId, ct);
        var max = await inventorySlots.GetMaxInventorySlotsAsync(userId, ct);
        var inventory = await db.Set<CharacterItem>().Where(x => x.CharacterId == characterId).ToListAsync(ct);
        if (inventory.Count >= max) throw new ShopException("inventory_full", "Your inventory is full.");
        var owned = inventory.Select(x => x.ItemId).ToHashSet();
        var catalog = await db.Set<Item>().Where(x => Pool.Contains(x.Id)).ToListAsync(ct);
        var selected = await resolve(characterId, owned, catalog);
        if (owned.Contains(selected.Item.Id)) throw new ShopException("already_owned", "You already own this item.");
        if (!await wallet.TrySpendAsync(userId, selected.Currency, selected.Price, ct))
            throw new ShopException("insufficient_currency", $"You do not have enough {Label(selected.Currency)}.");

        db.Set<CharacterItem>().Add(new CharacterItem
        {
            Id = Guid.NewGuid(), CharacterId = characterId, ItemId = selected.Item.Id,
            IsEquipped = false, AcquiredAt = DateTime.UtcNow,
        });
        db.Set<ShopPurchase>().Add(new ShopPurchase
        {
            Id = Guid.NewGuid(), UserId = userId, ClientPurchaseId = clientPurchaseId,
            OfferKey = offerKey, GrantedItemId = selected.Item.Id, Currency = selected.Currency,
            Price = selected.Price, PurchasedAtUtc = DateTime.UtcNow,
        });
        await db.SaveChangesAsync(ct);
        if (tx != null) await tx.CommitAsync(ct);
        return new ShopPurchaseResult(await GetAsync(userId, ct), ToDto(selected.Item));
    }

    private async Task<Guid> RequireCharacterAsync(Guid userId, CancellationToken ct) =>
        await characterIds.GetCharacterIdAsync(userId, ct)
        ?? throw new ShopException("character_not_found", "Create a character before using the shop.");

    private async Task<IDbContextTransaction?> BeginTransactionAsync(CancellationToken ct) =>
        db.Database.IsRelational() ? await db.Database.BeginTransactionAsync(ct) : null;

    private static List<Guid> GlobalRotation(List<Item> catalog, DateTime day)
    {
        var coins = Shuffle(catalog.Where(x => Prices[x.Rarity].Currency == ShopCurrency.Coins).Select(x => x.Id), $"{day:yyyy-MM-dd}:coins");
        var gems = Shuffle(catalog.Where(x => Prices[x.Rarity].Currency == ShopCurrency.Gems).Select(x => x.Id), $"{day:yyyy-MM-dd}:gems");
        var result = coins.Take(3).Concat(gems.Take(3)).ToList();
        var priorCoins = Shuffle(catalog.Where(x => Prices[x.Rarity].Currency == ShopCurrency.Coins).Select(x => x.Id), $"{day.AddDays(-1):yyyy-MM-dd}:coins");
        var priorGems = Shuffle(catalog.Where(x => Prices[x.Rarity].Currency == ShopCurrency.Gems).Select(x => x.Id), $"{day.AddDays(-1):yyyy-MM-dd}:gems");
        var prior = priorCoins.Take(3).Concat(priorGems.Take(3)).ToHashSet();
        if (result.ToHashSet().SetEquals(prior))
        {
            var replacement = coins.Skip(3).FirstOrDefault();
            if (replacement != Guid.Empty) result[2] = replacement;
            else if (gems.Count > 3) result[5] = gems[3];
        }
        return result;
    }

    private static bool CanBuildRefresh(List<Item> catalog, HashSet<Guid> owned, List<Guid> current) =>
        catalog.Count(x => Prices[x.Rarity].Currency == ShopCurrency.Coins && !owned.Contains(x.Id) && !current.Contains(x.Id)) >= 3 &&
        catalog.Count(x => Prices[x.Rarity].Currency == ShopCurrency.Gems && !owned.Contains(x.Id) && !current.Contains(x.Id)) >= 3;

    private static List<Guid> BuildRefresh(List<Item> catalog, HashSet<Guid> owned, List<Guid> current, Guid userId, DateTime day)
    {
        var eligible = catalog.Where(x => !owned.Contains(x.Id) && !current.Contains(x.Id)).ToList();
        var coins = Shuffle(eligible.Where(x => Prices[x.Rarity].Currency == ShopCurrency.Coins).Select(x => x.Id), $"{day:O}:{userId}:coins");
        var gems = Shuffle(eligible.Where(x => Prices[x.Rarity].Currency == ShopCurrency.Gems).Select(x => x.Id), $"{day:O}:{userId}:gems");
        return coins.Take(3).Concat(gems.Take(3)).ToList();
    }

    private static List<Guid> Shuffle(IEnumerable<Guid> source, string seed)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(seed));
        var random = new Random(BitConverter.ToInt32(bytes, 0));
        var values = source.OrderBy(x => x).ToList();
        for (var i = values.Count - 1; i > 0; i--) { var j = random.Next(i + 1); (values[i], values[j]) = (values[j], values[i]); }
        return values;
    }

    private static List<Guid> ParseIds(string json) => JsonSerializer.Deserialize<List<Guid>>(json) ?? [];
    private static Guid Id(int suffix) => Guid.Parse($"10000000-0000-0000-0000-{suffix:000000000000}");
    private static string Label(ShopCurrency currency) => currency == ShopCurrency.Coins ? "Coins" : "Gems";

    private static ItemDto ToDto(Item item) => new()
    {
        Id = item.Id, Name = item.Name, Description = item.Description, Icon = item.Icon,
        GearImageUrl = item.GearImageUrl, InventoryIconUrl = item.InventoryIconUrl,
        Rarity = item.Rarity.ToString(), SlotType = item.SlotType.ToString(),
        XpBonusPct = item.XpBonusPct, StrBonus = item.StrBonus, EndBonus = item.EndBonus,
        AgiBonus = item.AgiBonus, FlxBonus = item.FlxBonus, StaBonus = item.StaBonus,
        Category = item.Category.ToString(),
    };
}
