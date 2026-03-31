using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.SharedKernel.Ports;

public record ActivityLogPortResult(Guid ActivityId, long XpGained);

public interface IActivityLogPort
{
    Task<ActivityLogPortResult> LogExternalActivityAsync(
        Guid userId,
        ActivityType type,
        int durationMinutes,
        double? distanceKm,
        int? calories,
        int? heartRateAvg,
        string externalId,
        DateTime performedAt,
        CancellationToken ct = default);
}
