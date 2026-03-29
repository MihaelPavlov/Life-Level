using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Character.Domain.Events;

public record CharacterLeveledUpEvent(Guid UserId, int NewLevel) : IDomainEvent;
