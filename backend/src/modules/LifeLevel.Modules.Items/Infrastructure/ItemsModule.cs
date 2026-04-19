using LifeLevel.Modules.Items.Application.Ports;
using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Items.Infrastructure;

public static class ItemsModule
{
    public static IServiceCollection AddItemsModule(this IServiceCollection services)
    {
        services.AddScoped<ItemService>();
        services.AddScoped<IGearBonusReadPort>(sp => sp.GetRequiredService<ItemService>());
        services.AddScoped<ItemGrantService>();
        services.AddScoped<ILevelUpItemGrantPort, LevelUpItemGrantPortAdapter>();
        return services;
    }
}
