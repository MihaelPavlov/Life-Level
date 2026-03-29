using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.SharedKernel.Events;

public class InProcessEventPublisher(IServiceProvider sp) : IEventPublisher
{
    public async Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
        where TEvent : IDomainEvent
    {
        var handlers = sp.GetServices<IEventHandler<TEvent>>();
        foreach (var handler in handlers)
            await handler.HandleAsync(e, ct);
    }
}
