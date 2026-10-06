using LifeLevel.SharedKernel.DTOs;

namespace LifeLevel.SharedKernel.Ports;

/// <summary>Advances world travel by normalized Adventure km.</summary>
public interface IWorldZoneDistancePort
{
    /// <summary>
    /// Adds Adventure km to the user's current world-zone edge progress.
    /// Returns a non-null encounter when movement is stopped by an NPC on the path.
    /// Banks the distance when the user has no active destination set.
    /// </summary>
    Task<ActiveEncounterPortDto?> AddDistanceAsync(Guid userId, double km, CancellationToken ct = default);
}
