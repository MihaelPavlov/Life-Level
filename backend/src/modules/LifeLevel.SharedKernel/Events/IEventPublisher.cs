namespace LifeLevel.SharedKernel.Events;

public interface IEventPublisher
{
    Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
        where TEvent : IDomainEvent;
}
