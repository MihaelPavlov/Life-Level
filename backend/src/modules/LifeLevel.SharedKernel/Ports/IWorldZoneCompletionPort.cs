namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Port for completing a world-zone from outside the WorldZone module — used
/// by the Encounters damage pipeline when a world-zone boss (Boss.WorldZoneId
/// non-null) is defeated, to trigger the zone-complete + auto-advance flow.
/// Implemented by the WorldZone module (delegates to WorldZoneService.CompleteZoneAsync).
/// </summary>
public interface IWorldZoneCompletionPort
{
    Task CompleteBossZoneAsync(Guid userId, Guid worldZoneId, CancellationToken ct = default);
}
