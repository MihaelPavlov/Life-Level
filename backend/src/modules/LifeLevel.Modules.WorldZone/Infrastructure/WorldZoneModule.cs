using LifeLevel.Modules.WorldZone.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.WorldZone.Infrastructure;

public static class WorldZoneModule
{
    public static IServiceCollection AddWorldZoneModule(this IServiceCollection services)
    {
        services.AddScoped<WorldZoneService>();
        return services;
    }
}
