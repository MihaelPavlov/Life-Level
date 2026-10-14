using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.Activity.Domain.Entities;

public class TrackedSession
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid CharacterId { get; set; }
    public ActivityType Type { get; set; }
    public DateTime StartedAtUtc { get; set; }
    public DateTime EndedAtUtc { get; set; }
    public int ActiveSeconds { get; set; }
    public double DistanceMeters { get; set; }
    public int GpsSampleCount { get; set; }
    public bool GpsMeasured { get; set; }
    public Guid? RewardedActivityId { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
