using LifeLevel.Modules.Leaderboard.Application.UseCases;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Leaderboard.Infrastructure;

public static class LeaderboardModule
{
    public static IServiceCollection AddLeaderboardModule(this IServiceCollection services)
    {
        services.AddScoped<LeaderboardService>();
        return services;
    }
}
