namespace LifeLevel.SharedKernel.Ports;

public interface IWorldBlockerCompletionPort
{
    Task ClearBlockerAsync(
        Guid userId,
        Guid trailEncounterTemplateId,
        bool applyPendingDistance = true,
        CancellationToken ct = default);
}
