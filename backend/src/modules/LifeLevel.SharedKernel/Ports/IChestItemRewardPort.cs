namespace LifeLevel.SharedKernel.Ports;

public record ChestItemGrant(Guid ItemId, string Name, string Icon, string Rarity, string? InventoryIconUrl);

/// <summary>
/// Grants one random gear item the user does not own yet, of the given rarity, from the
/// Shop chest pool — the same draw a Shop chest makes, without the price. Used by
/// achievement stage chests. Returns null when nothing can be granted (no character,
/// every item of that rarity owned, or inventory full).
/// </summary>
public interface IChestItemRewardPort
{
    Task<ChestItemGrant?> GrantRandomUnownedAsync(Guid userId, string rarity, CancellationToken ct = default);
}
