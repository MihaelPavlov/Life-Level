using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.SharedKernel.Events;

public record ActivityLoggedEvent(
    Guid UserId,
    Guid ActivityId,
    ActivityType Type,
    int DurationMinutes,
    double DistanceKm,
    int Calories
) : IDomainEvent;
