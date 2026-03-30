namespace LifeLevel.SharedKernel.Ports;

public interface IMapNodeCompletedCountPort
{
    Task<Dictionary<Guid, int>> GetCompletedNodeCountsByZoneIdsAsync(
        Guid userId,
        IEnumerable<Guid> zoneIds,
        CancellationToken ct = default);
}
