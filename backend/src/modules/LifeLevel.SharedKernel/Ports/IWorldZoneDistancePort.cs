namespace LifeLevel.SharedKernel.Ports;

/// <summary>Advances the user's world-zone edge progress by the given distance in km.</summary>
public interface IWorldZoneDistancePort
{
    /// <summary>
    /// Adds km to the user's current world-zone edge progress.
    /// No-op when the user has no active destination set.
    /// </summary>
    Task AddDistanceAsync(Guid userId, double km, CancellationToken ct = default);
}
