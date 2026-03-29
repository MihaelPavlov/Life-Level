using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Streak.Domain.Events;

public record StreakBrokenEvent(Guid UserId, int PreviousStreak) : IDomainEvent;
