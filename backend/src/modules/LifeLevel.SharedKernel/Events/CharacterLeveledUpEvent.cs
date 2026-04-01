namespace LifeLevel.SharedKernel.Events;

public record CharacterLeveledUpEvent(Guid UserId, int PreviousLevel, int NewLevel) : IDomainEvent;
