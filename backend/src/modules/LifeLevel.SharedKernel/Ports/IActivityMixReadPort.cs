using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.SharedKernel.Ports;

/// <summary>Workouts and active minutes of one activity type within a time window.</summary>
public record ActivityMixEntry(ActivityType Type, int Workouts, int Minutes);

public interface IActivityMixReadPort
{
    /// <summary>
    /// Recent training mix for class detection. Step-count walks synced from
    /// Health Connect are excluded — they are not workouts.
    /// </summary>
    Task<IReadOnlyList<ActivityMixEntry>> GetRecentMixAsync(Guid userId, DateTime sinceUtc, CancellationToken ct = default);
}
