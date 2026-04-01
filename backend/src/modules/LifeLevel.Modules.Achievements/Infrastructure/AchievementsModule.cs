using LifeLevel.Modules.Achievements.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Achievements.Infrastructure;

public static class AchievementsModule
{
    public static IServiceCollection AddAchievementsModule(this IServiceCollection services)
    {
        services.AddScoped<AchievementService>();
        return services;
    }
}
