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
    public List<string> Errors { get; set; } = [];
}
