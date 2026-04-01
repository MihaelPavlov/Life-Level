using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure;

public static class EncountersModule
{
    public static IServiceCollection AddEncountersModule(this IServiceCollection services)
    {
        services.AddScoped<BossService>();
        services.AddScoped<ChestService>();
        services.AddScoped<IBossDefeatedCountReadPort, BossDefeatedCountAdapter>();
        return services;
    }
}
