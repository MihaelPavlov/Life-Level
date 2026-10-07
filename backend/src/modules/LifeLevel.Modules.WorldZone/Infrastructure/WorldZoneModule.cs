using LifeLevel.Modules.WorldZone.Application.Ports;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Application.EventHandlers;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.WorldZone.Infrastructure;

public static class WorldZoneModule
{
    public static IServiceCollection AddWorldZoneModule(this IServiceCollection services)
    {
        services.AddScoped<WorldZoneService>();
        services.AddScoped<MapReadService>();
        services.AddScoped<WorldChestService>();
        services.AddScoped<RegionChestService>();
        services.AddScoped<WorldDungeonService>();
        services.AddScoped<WorldBossBridgeService>();
        services.AddScoped<IZoneUnlockReadPort, ZoneUnlockReadPortAdapter>();
        services.AddScoped<IWorldZoneDistancePort>(sp => sp.GetRequiredService<WorldZoneService>());
        services.AddScoped<IWorldDungeonActivityPort>(sp => sp.GetRequiredService<WorldDungeonService>());
        services.AddScoped<IWorldZoneCompletionPort, WorldZoneCompletionPortAdapter>();
        services.AddScoped<IWorldZoneMetadataReadPort, WorldZoneMetadataReadPortAdapter>();
        services.AddScoped<IWorldBlockerCompletionPort, WorldBlockerCompletionPortAdapter>();
        services.AddScoped<IEventHandler<CharacterLeveledUpEvent>, LevelUpRegionAvailabilityHandler>();
        return services;
    }
}
