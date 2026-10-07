using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Modules.WorldZone.Application.Ports;

public sealed class WorldZoneMetadataReadPortAdapter(DbContext db)
    : IWorldZoneMetadataReadPort
{
    public async Task<IReadOnlyDictionary<Guid, WorldZoneMetadata>> GetMetadataAsync(
        IReadOnlyCollection<Guid> worldZoneIds,
        CancellationToken ct = default)
    {
        if (worldZoneIds.Count == 0)
            return new Dictionary<Guid, WorldZoneMetadata>();

        return await db.Set<WorldZoneEntity>()
            .Where(zone => worldZoneIds.Contains(zone.Id))
            .Select(zone => new WorldZoneMetadata(
                zone.Id,
                zone.Name,
                zone.Region.Name,
                zone.LevelRequirement))
            .ToDictionaryAsync(zone => zone.Id, ct);
    }
}
