namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Cross-module port for granting a specific catalog item to a user as a reward,
/// independent of the level-up path (<see cref="ILevelUpItemGrantPort"/>).
///
/// Implemented by the Items module over its idempotent, inventory-cap-aware
/// <c>ItemGrantService.GrantItemAsync</c>. Used by the Season Pass to hand out
/// item-type tier rewards.
/// </summary>
public interface IItemRewardGrantPort
{
    /// <summary>
    /// Grants <paramref name="itemId"/> to the user's character. Idempotent — granting
    /// the same item twice is a no-op. Returns the item's display name when a row was
    /// created or already existed, or <c>null</c> when it could not be granted
    /// (unknown item, no character, inventory full).
    /// </summary>
    Task<string?> GrantAsync(Guid userId, Guid itemId, CancellationToken ct = default);
}
