using LifeLevel.Modules.Modes.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Modes.Infrastructure;

public static class ModesModule
{
    public static IServiceCollection AddModesModule(this IServiceCollection services)
    {
        services.AddScoped<ModesService>();
        return services;
    }
}
