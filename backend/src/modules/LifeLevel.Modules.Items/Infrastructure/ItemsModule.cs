using LifeLevel.Modules.Items.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Items.Infrastructure;

public static class ItemsModule
{
    public static IServiceCollection AddItemsModule(this IServiceCollection services)
    {
        services.AddScoped<ItemService>();
        return services;
    }
}
