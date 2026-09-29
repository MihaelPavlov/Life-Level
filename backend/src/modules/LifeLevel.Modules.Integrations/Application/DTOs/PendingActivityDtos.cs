namespace LifeLevel.Modules.Integrations.Application.DTOs;

public class PendingActivityDto
{
    public Guid Id { get; set; }
    public string Provider { get; set; } = string.Empty;
    public string ActivityType { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public double? DistanceKm { get; set; }
    public int? Calories { get; set; }
    public DateTime PerformedAt { get; set; }
    /// <summary>"Pending" or "Duplicate".</summary>
    public string Status { get; set; } = "Pending";
    /// <summary>Provider of the workout this one duplicates (Duplicate only).</summary>
    public string? DuplicateOfProvider { get; set; }
    /// <summary>Base XP before gear / talent / class bonuses.</summary>
    public int PreviewXp { get; set; }
    public int PreviewStrength { get; set; }
    public int PreviewEndurance { get; set; }
    public int PreviewAgility { get; set; }
    public int PreviewFlexibility { get; set; }
    public int PreviewStamina { get; set; }
}

public class PendingActivityListDto
{
    public List<PendingActivityDto> Items { get; set; } = [];
    public int PendingCount { get; set; }
}

public class StagePendingRequest
{
    public List<ExternalActivityDto> Activities { get; set; } = [];
}

public class ImportPendingRequest
{
    public List<Guid> Ids { get; set; } = [];
}

public class ImportedPendingWorkoutDto
{
    public Guid PendingId { get; set; }
    public string ActivityType { get; set; } = string.Empty;
    public string Provider { get; set; } = string.Empty;
    public double? DistanceKm { get; set; }
    public int DurationMinutes { get; set; }
    public long XpGained { get; set; }
    public int Strength { get; set; }
    public int Endurance { get; set; }
    public int Agility { get; set; }
    public int Flexibility { get; set; }
    public int Stamina { get; set; }
}

public class ImportPendingResult
{
    public List<ImportedPendingWorkoutDto> Imported { get; set; } = [];
    public int Skipped { get; set; }
    public List<string> Errors { get; set; } = [];
    public long TotalXp { get; set; }
    public double TotalDistanceKm { get; set; }
    public int RemainingPending { get; set; }
}
