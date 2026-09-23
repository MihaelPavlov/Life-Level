using LifeLevel.Modules.Quest.Domain.Events;
using LifeLevel.Modules.Streak.Domain.Events;
using LifeLevel.Modules.Talents.Application.EventHandlers;
using LifeLevel.Modules.Talents.Application.UseCases;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Talents.Infrastructure;

public static class TalentsModule
{
    public static IServiceCollection AddTalentsModule(this IServiceCollection services)
    {
        services.AddScoped<TalentService>();
        services.AddScoped<ITalentBonusReadPort>(sp => sp.GetRequiredService<TalentService>());
        services.AddScoped<ITalentProfileReadPort>(sp => sp.GetRequiredService<TalentService>());
        services.AddScoped<ITalentStreakAssistPort>(sp => sp.GetRequiredService<TalentService>());
        services.AddScoped<IRewardCurrencyPort>(sp => sp.GetRequiredService<TalentService>());
        services.AddScoped<IShopWalletPort>(sp => sp.GetRequiredService<TalentService>());

        // Currency accrual — in-process domain event handlers.
        services.AddScoped<IEventHandler<ActivityLoggedEvent>, TalentCurrencyActivityHandler>();
        services.AddScoped<IEventHandler<BossDefeatedEvent>, TalentCurrencyBossHandler>();
        services.AddScoped<IEventHandler<CharacterLeveledUpEvent>, TalentCurrencyLevelUpHandler>();
        services.AddScoped<IEventHandler<ZoneCompletedEvent>, TalentCurrencyZoneHandler>();
        services.AddScoped<IEventHandler<RewardClaimedEvent>, TalentCurrencyRewardHandler>();
        services.AddScoped<IEventHandler<StreakBrokenEvent>, TalentStreakBrokenHandler>();

        return services;
    }
}
