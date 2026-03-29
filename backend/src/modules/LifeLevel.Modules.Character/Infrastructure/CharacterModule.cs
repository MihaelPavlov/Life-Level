using LifeLevel.Modules.Character.Application;
using LifeLevel.Modules.Character.Application.UseCases;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Character.Infrastructure;

public static class CharacterModule
{
    public static IServiceCollection AddCharacterModule(this IServiceCollection services)
    {
        services.AddScoped<CharacterService>();
        services.AddScoped<ICharacterXpPort>(sp => (ICharacterXpPort)sp.GetRequiredService<CharacterService>());
        services.AddScoped<ICharacterStatPort>(sp => (ICharacterStatPort)sp.GetRequiredService<CharacterService>());
        services.AddScoped<ICharacterLevelReadPort>(sp => (ICharacterLevelReadPort)sp.GetRequiredService<CharacterService>());
        services.AddScoped<ICharacterInfoPort>(sp => (ICharacterInfoPort)sp.GetRequiredService<CharacterService>());
        services.AddScoped<ICharacterIdReadPort>(sp => sp.GetRequiredService<CharacterService>());
        services.AddScoped<IEventHandler<UserRegisteredEvent>, CharacterCreatedHandler>();
        return services;
    }
}
