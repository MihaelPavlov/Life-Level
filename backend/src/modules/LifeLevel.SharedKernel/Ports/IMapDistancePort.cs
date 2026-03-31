namespace LifeLevel.SharedKernel.Ports;

/// <summary>Advances the user's map position by the given distance in km.</summary>
public interface IMapDistancePort
{
    /// <summary>
    /// Adds km to the user's current edge progress.
    /// No-op when the user has no active destination.
    /// </summary>
    Task AddDistanceAsync(Guid userId, double km, CancellationToken ct = default);
}
