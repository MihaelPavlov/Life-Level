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

        var owned = await db.Set<CharacterItem>().Where(x => x.CharacterId == characterId)
            .Select(x => x.ItemId).ToHashSetAsync(ct);
        var candidates = await db.Set<Item>()
            .Where(x => ShopService.ChestPool.Contains(x.Id) && x.Rarity == wanted)
            .ToListAsync(ct);
        candidates = candidates.Where(x => !owned.Contains(x.Id)).ToList();
        if (candidates.Count == 0) return null;

        var item = candidates[RandomNumberGenerator.GetInt32(candidates.Count)];
        var result = await itemGrantService.GrantItemAsync(userId, item.Id, ct);
        if (result.Item == null) return null;
        return new ChestItemGrant(item.Id, item.Name, item.Icon, item.Rarity.ToString(), item.InventoryIconUrl);
    }
}
