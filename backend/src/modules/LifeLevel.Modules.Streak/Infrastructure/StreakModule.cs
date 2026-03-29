using LifeLevel.Modules.Streak.Application;
using LifeLevel.Modules.Streak.Application.UseCases;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Streak.Infrastructure;

public static class StreakModule
{
    public static IServiceCollection AddStreakModule(this IServiceCollection services)
    {
        services.AddScoped<StreakService>();
        services.AddScoped<IStreakReadPort>(sp => sp.GetRequiredService<StreakService>());
        services.AddScoped<IStreakShieldPort>(sp => sp.GetRequiredService<StreakService>());
        services.AddScoped<IStreakDailyReset>(sp => sp.GetRequiredService<StreakService>());
        services.AddScoped<IEventHandler<ActivityLoggedEvent>, StreakActivityHandler>();
        return services;
    }
}
