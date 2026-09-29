using LifeLevel.Modules.Integrations.Application.UseCases;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace LifeLevel.Modules.Integrations.Infrastructure;

public static class IntegrationsModule
{
    public static IServiceCollection AddIntegrationsModule(this IServiceCollection services)
    {
        services.AddScoped<HealthSyncService>();
        services.AddScoped<PendingActivityService>();
        services.TryAddScoped<INotificationPort, NoOpNotificationPort>();
        services.AddScoped<StravaOAuthService>();
        services.AddScoped<StravaWebhookService>();
        services.AddScoped<GarminOAuthService>();
        services.AddScoped<GarminWebhookService>();
        services.AddScoped<OnboardingImportService>();
        return services;
    }
}
