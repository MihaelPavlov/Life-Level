namespace LifeLevel.SharedKernel.Events;

public record CharacterRankChangedEvent(Guid UserId, string NewRank) : IDomainEvent;
