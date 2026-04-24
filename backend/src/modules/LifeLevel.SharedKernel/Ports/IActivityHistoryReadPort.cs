namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Cross-module activity-record DTO used by features that need to read the
/// raw activity log without taking a compile-time dependency on the Activity
/// module's entity types.
/// </summary>
public sealed record ActivityRecordDto(
    Guid Id,
    string Type,            // "Running", "Gym", ... (ActivityType enum name)
    int DurationMinutes,
    double DistanceKm,
    int Calories,
    DateTime LoggedAt);

/// <summary>
/// Port to list raw activity rows for a user within a UTC time window.
/// Consumed by the Encounters module (boss damage-history endpoint) to
/// re-compute per-activity damage values without persisting a dedicated
/// damage-event table.
/// </summary>
public interface IActivityHistoryReadPort
{
    Task<IReadOnlyList<ActivityRecordDto>> ListForUserBetweenAsync(
        Guid userId, DateTime fromUtc, DateTime toUtc, CancellationToken ct = default);
}
