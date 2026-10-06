using LifeLevel.Modules.Integrations.Domain.Entities;

namespace LifeLevel.Modules.Integrations.Application.DTOs;

public class ExternalActivityDto
{
    public string Provider { get; set; } = string.Empty;       // "HealthKit" | "HealthConnect" | "Strava"
    public string ExternalId { get; set; } = string.Empty;     // provider-scoped native ID
    public string ActivityType { get; set; } = string.Empty;   // maps to our ActivityType enum
    public int DurationMinutes { get; set; }
    public double? DistanceKm { get; set; }
    public int? Calories { get; set; }
    public int? HeartRateAvg { get; set; }
    /// <summary>Real step count; only the phone's daily step walks send it.</summary>
    public int? Steps { get; set; }
    public ActivityRecordingMethod RecordingMethod { get; set; } = ActivityRecordingMethod.Unknown;
    public DateTime PerformedAt { get; set; }
}

public class SyncBatchRequest
{
    public List<ExternalActivityDto> Activities { get; set; } = [];
}

public class SyncResult
{
    public int Imported { get; set; }
    public int Skipped { get; set; }
    public int RejectedManual { get; set; }
    public double TotalAdventureDistanceKm { get; set; }
    public List<string> Errors { get; set; } = [];
}
