namespace LifeLevel.Modules.Integrations.Domain.Entities;

public enum ActivityRecordingMethod
{
    Unknown = 0,
    Active = 1,
    Automatic = 2,
    Manual = 3,
}

public enum PendingActivityStatus
{
    /// <summary>Waiting for the player to import it.</summary>
    Pending = 0,
    /// <summary>Imported into the game; XP was awarded.</summary>
    Imported = 1,
    /// <summary>The same workout already came in from another provider. Never imported.</summary>
    Duplicate = 2,
    /// <summary>Visible once, but permanently ineligible for game rewards.</summary>
    Rejected = 3,
}

/// <summary>
/// A workout a provider told us about that has not been turned into XP yet.
/// Strava / Garmin webhooks and the phone's Health Connect / Apple Health read
/// all land here; the player reviews and imports them from Home.
/// The provider payload is stored in full so importing never calls the provider again.
/// </summary>
public class PendingActivity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Provider { get; set; } = string.Empty;
    public string ExternalId { get; set; } = string.Empty;
    public string ActivityType { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public double? DistanceKm { get; set; }
    public int? Calories { get; set; }
    public int? HeartRateAvg { get; set; }
    public int? Steps { get; set; }
    public ActivityRecordingMethod RecordingMethod { get; set; }
    public DateTime PerformedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public PendingActivityStatus Status { get; set; }
    /// <summary>Set when <see cref="Status"/> is Duplicate: the workout it duplicates.</summary>
    public Guid? DuplicateOfId { get; set; }
    public Guid? ImportedActivityId { get; set; }
    public long XpAwarded { get; set; }
    public DateTime? ImportedAt { get; set; }
    public string? RejectionReason { get; set; }
    public DateTime? AcknowledgedAt { get; set; }
}
