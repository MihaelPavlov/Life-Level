namespace LifeLevel.SharedKernel.Ports;

public interface IMapNodeCountPort
{
    /// <summary>Returns a dictionary of WorldZoneId → node count for the given zone IDs.</summary>
    Task<Dictionary<Guid, int>> GetNodeCountsByZoneIdsAsync(IEnumerable<Guid> zoneIds, CancellationToken ct = default);
}
