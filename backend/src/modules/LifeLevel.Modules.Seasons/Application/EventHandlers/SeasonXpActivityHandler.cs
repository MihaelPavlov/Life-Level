using LifeLevel.Modules.Seasons.Application.UseCases;
using LifeLevel.Modules.Seasons.Domain;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Seasons.Application.EventHandlers;

/// <summary>Awards flat Season XP for every logged activity while a season is active.</summary>
public class SeasonXpActivityHandler(SeasonService seasons) : IEventHandler<ActivityLoggedEvent>
{
    public Task HandleAsync(ActivityLoggedEvent e, CancellationToken ct = default) =>
        seasons.AddSeasonXpAsync(
            e.UserId,
            SeasonXpRules.ForActivity(e.Type, e.DurationMinutes, e.DistanceKm),
            ct);
}
