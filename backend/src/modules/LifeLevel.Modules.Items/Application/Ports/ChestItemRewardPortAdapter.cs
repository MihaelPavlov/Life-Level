using System.Security.Cryptography;
using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Items.Application.Ports;

/// <summary>
/// Items-module adapter for <see cref="IChestItemRewardPort"/>: draws from the Shop chest
/// pool like <see cref="ShopService.PurchaseChestAsync"/> and grants through
/// <see cref="ItemGrantService"/> (inventory-cap aware).
/// </summary>
public class ChestItemRewardPortAdapter(
    DbContext db,
    ItemGrantService itemGrantService,
    ICharacterIdReadPort characterIds) : IChestItemRewardPort
{
    public async Task<ChestItemGrant?> GrantRandomUnownedAsync(Guid userId, string rarity, CancellationToken ct = default)
    {
        if (!Enum.TryParse<ItemRarity>(rarity, true, out var wanted)) return null;
        var characterId = await characterIds.GetCharacterIdAsync(userId, ct);
        if (characterId is null) return null;

        var ownedItems = await db.Set<CharacterItem>().Where(x => x.CharacterId == characterId)
            .Select(x => new { x.ItemId, x.Item.Name }).ToListAsync(ct);
        var ownedIds = ownedItems.Select(x => x.ItemId).ToHashSet();
        var ownedNames = ownedItems.Select(x => x.Name.Trim()).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var candidates = await db.Set<Item>()
            .Where(x => ShopService.ChestPool.Contains(x.Id) && x.Rarity == wanted)
            .ToListAsync(ct);
        candidates = candidates.Where(x => !ownedIds.Contains(x.Id) && !ownedNames.Contains(x.Name.Trim())).ToList();
        if (candidates.Count == 0) return null;

        var item = candidates[RandomNumberGenerator.GetInt32(candidates.Count)];
        var result = await itemGrantService.GrantItemAsync(userId, item.Id, ct);
        if (result.Item == null) return null;
        return new ChestItemGrant(item.Id, item.Name, item.Icon, item.Rarity.ToString(), item.InventoryIconUrl);
    }
}
