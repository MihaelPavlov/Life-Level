namespace LifeLevel.SharedKernel.Events;

public record BossDefeatedEvent(Guid UserId, Guid BossId) : IDomainEvent;
