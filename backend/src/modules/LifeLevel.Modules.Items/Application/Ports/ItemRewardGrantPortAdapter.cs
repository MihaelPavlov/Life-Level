using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Items.Application.Ports;

/// <summary>
/// Items-module adapter for <see cref="IItemRewardGrantPort"/>. Thin wrapper over
/// <see cref="ItemGrantService.GrantItemAsync"/> (idempotent, inventory-cap aware).
/// Mirrors <see cref="LevelUpItemGrantPortAdapter"/>.
/// </summary>
public class ItemRewardGrantPortAdapter(ItemGrantService itemGrantService, DbContext db) : IItemRewardGrantPort
{
    public async Task<string?> GrantAsync(Guid userId, Guid itemId, CancellationToken ct = default)
    {
        var result = await itemGrantService.GrantItemAsync(userId, itemId, ct);
        if (result.Item == null) return null;
        return await db.Set<Item>()
            .Where(i => i.Id == itemId)
            .Select(i => i.Name)
            .FirstOrDefaultAsync(ct);
    }
}
