using LifeLevel.Modules.Quest.Domain.Events;
using LifeLevel.Modules.Seasons.Application.UseCases;
using LifeLevel.Modules.Seasons.Domain;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Seasons.Application.EventHandlers;

/// <summary>Awards flat Season XP for every completed quest while a season is active.</summary>
public class SeasonXpQuestHandler(SeasonService seasons) : IEventHandler<QuestCompletedEvent>
{
    public Task HandleAsync(QuestCompletedEvent e, CancellationToken ct = default) =>
        seasons.AddSeasonXpAsync(e.UserId, SeasonXpRules.PerQuestComplete, ct);
}
