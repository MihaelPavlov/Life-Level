namespace LifeLevel.SharedKernel.Ports;

public sealed record WorldZoneMetadata(
    Guid Id,
    string Name,
    string RegionName,
    int LevelRequirement);

/// <summary>
/// Read-only bridge for encounter presentation data owned by the WorldZone
/// module. Keeping this contract in SharedKernel avoids a module cycle.
/// </summary>
public interface IWorldZoneMetadataReadPort
{
    Task<IReadOnlyDictionary<Guid, WorldZoneMetadata>> GetMetadataAsync(
        IReadOnlyCollection<Guid> worldZoneIds,
        CancellationToken ct = default);
}
