namespace LifeLevel.SharedKernel.Events;

public record UserRegisteredEvent(Guid UserId, string Username) : IDomainEvent;
