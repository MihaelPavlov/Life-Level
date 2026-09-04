using LifeLevel.Modules.Guild.Application.UseCases;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace LifeLevel.Modules.Guild.Infrastructure;

public static class GuildModule
{
    public static IServiceCollection AddGuildModule(this IServiceCollection services)
    {
        services.AddScoped<GuildService>();
        services.AddScoped<IGuildRaidActivityPort>(sp => sp.GetRequiredService<GuildService>());
        services.AddScoped<IGuildRaidMaintenancePort>(sp => sp.GetRequiredService<GuildService>());
        services.TryAddScoped<IGuildRaidRealtimePort, NoOpGuildRaidRealtimePort>();
        services.TryAddScoped<INotificationPort, NoOpNotificationPort>();
        return services;
    }
}
