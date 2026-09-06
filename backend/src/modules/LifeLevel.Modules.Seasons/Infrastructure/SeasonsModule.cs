using LifeLevel.Modules.Quest.Domain.Events;
using LifeLevel.Modules.Seasons.Application.EventHandlers;
using LifeLevel.Modules.Seasons.Application.UseCases;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Seasons.Infrastructure;

public static class SeasonsModule
{
    public static IServiceCollection AddSeasonsModule(this IServiceCollection services)
    {
        services.AddScoped<SeasonService>();
        services.AddScoped<ISeasonRolloverPort>(sp => sp.GetRequiredService<SeasonService>());

        // Season XP accrual — in-process domain event handlers.
        services.AddScoped<IEventHandler<ActivityLoggedEvent>, SeasonXpActivityHandler>();
        services.AddScoped<IEventHandler<QuestCompletedEvent>, SeasonXpQuestHandler>();
        services.AddScoped<IEventHandler<BossDefeatedEvent>, SeasonXpBossHandler>();

        return services;
    }
}
