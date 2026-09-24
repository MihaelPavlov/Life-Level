namespace LifeLevel.SharedKernel.Ports;

public sealed record TaskEligibilitySnapshot(
    bool HasCompletableZone,
    int ReachableUnopenedChests,
    bool HasActiveBoss,
    bool HasActiveGuildRaid,
    bool CanCompleteCurrentRegion);

public interface ITaskEligibilityReadPort
{
    Task<TaskEligibilitySnapshot> GetAsync(Guid userId, CancellationToken ct = default);
}
