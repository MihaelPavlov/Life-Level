using LifeLevel.Modules.Seasons.Application.UseCases;
using LifeLevel.Modules.Seasons.Domain;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Seasons.Application.EventHandlers;

/// <summary>Awards flat Season XP for every boss defeat while a season is active.</summary>
public class SeasonXpBossHandler(SeasonService seasons) : IEventHandler<BossDefeatedEvent>
{
    public Task HandleAsync(BossDefeatedEvent e, CancellationToken ct = default) =>
        seasons.AddSeasonXpAsync(e.UserId, SeasonXpRules.PerBossDefeat, ct);
}
