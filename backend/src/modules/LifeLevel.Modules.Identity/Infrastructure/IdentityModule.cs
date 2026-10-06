using LifeLevel.Modules.Identity.Application.UseCases;
using LifeLevel.Modules.Identity.Application.Ports.Out;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Identity.Infrastructure;

public static class IdentityModule
{
    public static IServiceCollection AddIdentityModule(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.Configure<GoogleAuthOptions>(configuration.GetSection(GoogleAuthOptions.Section));
        services.AddSingleton<IGoogleTokenVerifier, GoogleTokenVerifier>();
        services.Configure<AppleAuthOptions>(configuration.GetSection(AppleAuthOptions.Section));
        services.AddSingleton<IAppleTokenVerifier, AppleTokenVerifier>();
        services.AddScoped<JwtService>();
        services.AddScoped<AuthService>();
        services.AddScoped<AccountService>();
        return services;
    }
}
