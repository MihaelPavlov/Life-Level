namespace LifeLevel.SharedKernel.Events;

public record RewardClaimedEvent(Guid UserId, string Source) : IDomainEvent;
