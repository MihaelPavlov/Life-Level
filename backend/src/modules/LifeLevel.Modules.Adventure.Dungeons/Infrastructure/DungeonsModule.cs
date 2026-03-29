using LifeLevel.Modules.Adventure.Dungeons.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Adventure.Dungeons.Infrastructure;

public static class DungeonsModule
{
    public static IServiceCollection AddDungeonsModule(this IServiceCollection services)
    {
        services.AddScoped<DungeonService>();
        services.AddScoped<CrossroadsService>();
        return services;
    }
}
