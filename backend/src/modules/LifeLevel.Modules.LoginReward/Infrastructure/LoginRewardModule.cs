using LifeLevel.Modules.LoginReward.Application.UseCases;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.LoginReward.Infrastructure;

public static class LoginRewardModule
{
    public static IServiceCollection AddLoginRewardModule(this IServiceCollection services)
    {
        services.AddScoped<LoginRewardService>();
        services.AddScoped<ILoginRewardReadPort>(sp => sp.GetRequiredService<LoginRewardService>());
        services.AddScoped<ILoginRewardDailyReset>(sp => sp.GetRequiredService<LoginRewardService>());
        return services;
    }
}
