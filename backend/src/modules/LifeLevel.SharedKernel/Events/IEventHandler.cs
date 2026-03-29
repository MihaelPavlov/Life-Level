namespace LifeLevel.SharedKernel.Events;

public interface IEventHandler<TEvent> where TEvent : IDomainEvent
{
    Task HandleAsync(TEvent e, CancellationToken ct = default);
}
