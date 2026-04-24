namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Read-side port for boss-defeat state. Lets modules outside Encounters
/// (e.g. WorldZone map reads) answer "has this user defeated the boss for
/// this world zone?" without depending on Encounters internals.
/// </summary>
public interface IBossDefeatReadPort
{
    /// <summary>
    /// Returns the set of <c>WorldZoneId</c> values where the user's
    /// <c>UserBossState</c> is marked defeated. Only populated for
    /// world-zone bosses — legacy local-map bosses with <c>WorldZoneId</c>
    /// null are excluded.
    /// </summary>
    Task<HashSet<Guid>> GetDefeatedWorldZoneIdsAsync(Guid userId, CancellationToken ct = default);
}
