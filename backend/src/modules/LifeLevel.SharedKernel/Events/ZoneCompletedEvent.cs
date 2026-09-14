namespace LifeLevel.SharedKernel.Events;

public record ZoneCompletedEvent(Guid UserId, Guid ZoneId) : IDomainEvent;
