using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Events;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.SharedKernel;

public static class SharedKernelExtensions
{
    public static IServiceCollection AddSharedKernel(this IServiceCollection services)
    {
        services.AddScoped<IEventPublisher, InProcessEventPublisher>();
        services.AddSingleton<ICurrentClock, SystemClock>();
        return services;
    }
}
