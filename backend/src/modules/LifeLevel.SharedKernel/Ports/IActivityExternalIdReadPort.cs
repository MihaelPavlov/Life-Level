namespace LifeLevel.SharedKernel.Ports;

public interface IActivityExternalIdReadPort
{
    /// <summary>
    /// Returns the Activity ID if an activity row already exists for the given
    /// characterId + externalId combination, or null if none exists.
    /// Used by the Integrations module to detect torn-write state without taking
    /// a direct compile-time dependency on the Activity module's entity types.
    /// </summary>
    Task<Guid?> FindActivityIdByExternalIdAsync(Guid characterId, string externalId, CancellationToken ct = default);
}
