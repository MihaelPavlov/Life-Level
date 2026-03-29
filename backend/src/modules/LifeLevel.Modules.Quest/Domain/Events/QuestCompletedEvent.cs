using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Quest.Domain.Events;

public record QuestCompletedEvent(Guid UserId, Guid QuestId, string QuestTitle, long RewardXp) : IDomainEvent;
