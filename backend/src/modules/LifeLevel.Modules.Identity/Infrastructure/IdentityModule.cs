using LifeLevel.Modules.Identity.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Identity.Infrastructure;

public static class IdentityModule
{
    public static IServiceCollection AddIdentityModule(this IServiceCollection services)
    {
        services.AddScoped<JwtService>();
        services.AddScoped<AuthService>();
        return services;
    }
}
