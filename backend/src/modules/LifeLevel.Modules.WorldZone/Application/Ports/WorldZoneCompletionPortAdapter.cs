using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Modules.WorldZone.Application.Ports;

/// <summary>
/// Adapter for <see cref="IWorldZoneCompletionPort"/>. Lets the Encounters
/// damage pipeline complete a world-zone boss fight (triggering zone complete
/// + auto-advance to the next region's entry zone) without a direct project
/// reference to the WorldZone module.
/// </summary>
public class WorldZoneCompletionPortAdapter(
    WorldZoneService worldZoneService,
    DbContext? db = null,
    IEventPublisher? events = null) : IWorldZoneCompletionPort
{
    public async Task CompleteBossZoneAsync(Guid userId, Guid worldZoneId, CancellationToken ct = default)
    {
        await worldZoneService.CompleteZoneAsync(userId, worldZoneId);
        if (db != null && events != null)
        {
            var regionId = await db.Set<WorldZoneEntity>().AsNoTracking()
                .Where(z => z.Id == worldZoneId).Select(z => z.RegionId).FirstAsync(ct);
            await events.PublishAsync(new RegionCompletedEvent(userId, regionId), ct);
        }
    }
}
