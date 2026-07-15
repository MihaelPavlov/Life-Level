using LifeLevel.SharedKernel.DTOs;

namespace LifeLevel.SharedKernel.Ports;

/// <summary>Advances the user's world-zone edge progress by the given distance in km.</summary>
public interface IWorldZoneDistancePort
{
    /// <summary>
    /// Adds km to the user's current world-zone edge progress.
    /// Returns a non-null encounter when movement is stopped by an NPC on the path.
    /// No-op (returns null) when the user has no active destination set.
    /// </summary>
    Task<ActiveEncounterPortDto?> AddDistanceAsync(Guid userId, double km, CancellationToken ct = default);
}
