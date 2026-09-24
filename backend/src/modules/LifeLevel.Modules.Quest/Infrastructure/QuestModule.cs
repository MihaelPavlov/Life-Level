using LifeLevel.Modules.Quest.Application.UseCases;
using LifeLevel.Modules.Quest.Application.EventHandlers;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Quest.Infrastructure;

public static class QuestModule
{
    public static IServiceCollection AddQuestModule(this IServiceCollection services)
    {
        services.AddScoped<QuestService>();
        services.AddScoped<IDailyQuestReadPort>(sp => sp.GetRequiredService<QuestService>());
        services.AddScoped<IQuestProgressPort>(sp => sp.GetRequiredService<QuestService>());
        services.AddScoped<IEventHandler<ZoneCompletedEvent>, QuestGameProgressHandler>();
        services.AddScoped<IEventHandler<ChestOpenedEvent>, QuestGameProgressHandler>();
        services.AddScoped<IEventHandler<BossContributionEvent>, QuestGameProgressHandler>();
        services.AddScoped<IEventHandler<BossDefeatedEvent>, QuestGameProgressHandler>();
        services.AddScoped<IEventHandler<GuildRaidContributionEvent>, QuestGameProgressHandler>();
        services.AddScoped<IEventHandler<GuildRaidWonEvent>, QuestGameProgressHandler>();
        services.AddScoped<IEventHandler<RegionCompletedEvent>, QuestGameProgressHandler>();
        return services;
    }
}
