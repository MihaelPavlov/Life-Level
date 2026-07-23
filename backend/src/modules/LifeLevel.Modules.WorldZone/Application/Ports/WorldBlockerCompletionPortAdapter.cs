using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.WorldZone.Application.Ports;

public class WorldBlockerCompletionPortAdapter(WorldZoneService worldZoneService) : IWorldBlockerCompletionPort
{
    public Task ClearBlockerAsync(
        Guid userId,
        Guid trailEncounterTemplateId,
        bool applyPendingDistance = true,
        CancellationToken ct = default)
        => worldZoneService.ClearBlockerEncounterAsync(
            userId,
            trailEncounterTemplateId,
            applyPendingDistance,
            ct);
}
