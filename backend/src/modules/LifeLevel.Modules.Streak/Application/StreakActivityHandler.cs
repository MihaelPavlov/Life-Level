using LifeLevel.Modules.Streak.Application.UseCases;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Streak.Application;

public class StreakActivityHandler(StreakService streakService) : IEventHandler<ActivityLoggedEvent>
{
    public async Task HandleAsync(ActivityLoggedEvent e, CancellationToken ct = default)
    {
        await streakService.RecordActivityDayAsync(e.UserId, DateTime.UtcNow.Date, ct);
    }
}
