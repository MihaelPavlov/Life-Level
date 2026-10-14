using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.Activity.Application.DTOs;

public sealed class FinishTrackedSessionRequest
{
    public Guid SessionId { get; set; }
    public ActivityType Type { get; set; }
    public DateTime StartedAtUtc { get; set; }
    public DateTime EndedAtUtc { get; set; }
    public int ActiveSeconds { get; set; }
    public double DistanceMeters { get; set; }
    public int GpsSampleCount { get; set; }
    public int GpsCoveredSeconds { get; set; }
}

public sealed record TrackedSessionDto(
    Guid SessionId, ActivityType Type, DateTime StartedAtUtc,
    DateTime EndedAtUtc, int ActiveSeconds, double DistanceMeters,
    bool GpsMeasured, Guid? RewardedActivityId,
    LogActivityResult? Reward);
