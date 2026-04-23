using LifeLevel.Modules.WorldZone.Application.Ports;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.WorldZone.Infrastructure;

public static class WorldZoneModule
{
    public static IServiceCollection AddWorldZoneModule(this IServiceCollection services)
    {
        services.AddScoped<WorldZoneService>();
        services.AddScoped<MapReadService>();
        services.AddScoped<IZoneUnlockReadPort, ZoneUnlockReadPortAdapter>();
        services.AddScoped<IWorldZoneDistancePort>(sp => sp.GetRequiredService<WorldZoneService>());
        return services;
    }
}
