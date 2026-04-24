namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Port for initializing per-user fight state against a spawned Boss. Called by
/// cross-module callers (e.g. WorldBossBridgeService in the WorldZone module)
/// so they don't need a direct reference to the Encounters module internals.
/// </summary>
public interface IBossSpawnPort
{
    /// <summary>
    /// Ensure a UserBossState row exists for (userId, bossId). Idempotent —
    /// no-op when state already exists. Initializes HpDealt = 0, IsDefeated = false.
    /// </summary>
    Task EnsureUserStateAsync(Guid userId, Guid bossId, CancellationToken ct = default);
}
