using LifeLevel.Modules.Integrations.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Integrations.Infrastructure;

public static class IntegrationsModule
{
    public static IServiceCollection AddIntegrationsModule(this IServiceCollection services)
    {
        services.AddScoped<HealthSyncService>();
        services.AddScoped<StravaOAuthService>();
        services.AddScoped<StravaWebhookService>();
        services.AddScoped<GarminOAuthService>();
        services.AddScoped<GarminWebhookService>();
        return services;
    }
}
