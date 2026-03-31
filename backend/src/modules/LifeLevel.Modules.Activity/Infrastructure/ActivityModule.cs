using LifeLevel.Modules.Activity.Application.UseCases;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Activity.Infrastructure;

public static class ActivityModule
{
    public static IServiceCollection AddActivityModule(this IServiceCollection services)
    {
        services.AddScoped<ActivityService>();
        services.AddScoped<IActivityStatsReadPort>(sp => sp.GetRequiredService<ActivityService>());
        services.AddScoped<IActivityLogPort>(sp => sp.GetRequiredService<ActivityService>());
        services.AddScoped<IActivityExternalIdReadPort>(sp => sp.GetRequiredService<ActivityService>());
        return services;
    }
}
