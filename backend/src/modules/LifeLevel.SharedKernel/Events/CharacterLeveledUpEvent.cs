namespace LifeLevel.SharedKernel.Events;

public record CharacterLeveledUpEvent(
    Guid UserId,
    Guid ReceiptId,
    int PreviousLevel,
    int NewLevel) : IDomainEvent;
