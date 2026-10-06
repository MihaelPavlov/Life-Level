using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.SharedKernel.Ports;

public record ActivityLogPortResult(Guid ActivityId, long XpGained, double AdventureDistanceKm = 0);

/// <summary>One workout imported from the player's history during onboarding.</summary>
public record HistoricalActivityResult(
    Guid ActivityId,
    ActivityType Type,
    int DurationMinutes,
    double DistanceKm,
    double AdventureDistanceKm,
    long XpGained,
    DateTime PerformedAt);

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
        int? steps = null,
        CancellationToken ct = default);

    /// <summary>
    /// Stores a past workout during onboarding. Applies stat gains and banks its
    /// distance, but does NOT award XP (the caller awards the batch total once),
    /// and skips quests, bosses, guild raids and activity events.
    /// XP is valued at <see cref="HistoryXpRate"/> of a live workout.
    /// </summary>
    Task<HistoricalActivityResult> ImportHistoricalActivityAsync(
        Guid userId,
        ActivityType type,
        int durationMinutes,
        double? distanceKm,
        int? calories,
        int? heartRateAvg,
        string externalId,
        DateTime performedAt,
        int? steps = null,
        CancellationToken ct = default);

    /// <summary>Share of live XP a historical workout is worth.</summary>
    const double HistoryXpRate = 0.5;
}
