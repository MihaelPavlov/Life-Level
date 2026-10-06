using LifeLevel.Modules.Waitlist.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Waitlist.Infrastructure;

public static class WaitlistModule
{
    public static IServiceCollection AddWaitlistModule(this IServiceCollection services)
    {
        services.AddScoped<WaitlistService>();
        return services;
    }
}
