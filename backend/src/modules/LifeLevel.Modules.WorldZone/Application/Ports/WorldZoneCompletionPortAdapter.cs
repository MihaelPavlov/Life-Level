using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.WorldZone.Application.Ports;

/// <summary>
/// Adapter for <see cref="IWorldZoneCompletionPort"/>. Lets the Encounters
/// damage pipeline complete a world-zone boss fight (triggering zone complete
/// + auto-advance to the next region's entry zone) without a direct project
/// reference to the WorldZone module.
/// </summary>
public class WorldZoneCompletionPortAdapter(WorldZoneService worldZoneService) : IWorldZoneCompletionPort
{
    public async Task CompleteBossZoneAsync(Guid userId, Guid worldZoneId, CancellationToken ct = default)
    {
        await worldZoneService.CompleteZoneAsync(userId, worldZoneId);
    }
}
