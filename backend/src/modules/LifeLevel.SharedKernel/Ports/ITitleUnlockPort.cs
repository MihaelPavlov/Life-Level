namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Cross-module port for explicit title unlocks keyed by a stable catalog key
/// (e.g. <c>"novice-adventurer"</c>), as opposed to the criteria-evaluated auto-grant path
/// used by streak/boss/rank titles.
///
/// Called by the Tutorial flow (LL-035 step 7) and any future feature that needs to grant a
/// specific title as a reward rather than by matching a dynamic condition.
///
/// Implementations MUST be idempotent: granting the same <paramref name="titleKey"/> to the
/// same character more than once is a no-op and MUST NOT throw. Implementations MAY log a
/// warning when the key is unknown, but they MUST NOT throw — callers should not have to
/// defend against misconfigured catalogs at runtime.
/// </summary>
public interface ITitleUnlockPort
{
    /// <summary>
    /// Grants the title identified by <paramref name="titleKey"/> to the given character.
    /// Returns <c>true</c> if a new <c>CharacterTitle</c> row was created, <c>false</c> if
    /// the title was already earned or the key is unknown.
    /// </summary>
    Task<bool> UnlockAsync(Guid characterId, string titleKey, CancellationToken ct = default);
}
