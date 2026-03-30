using LifeLevel.Modules.Quest.Application.UseCases;
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
        return services;
    }
}
