using LifeLevel.Modules.Quest.Application.UseCases;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Quest.Application;

public class QuestActivityHandler(QuestService questService) : IEventHandler<ActivityLoggedEvent>
{
    public async Task HandleAsync(ActivityLoggedEvent e, CancellationToken ct = default)
    {
        await questService.UpdateProgressFromActivityAsync(
            e.UserId,
            e.Type,
            e.DurationMinutes,
            e.DistanceKm > 0 ? e.DistanceKm : null,
            e.Calories > 0 ? e.Calories : null);
    }
}
