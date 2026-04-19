using LifeLevel.Modules.Streak.Domain.Events;
using LifeLevel.SharedKernel.Ports;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Notifications.Application.EventHandlers;

/// <summary>
/// Listens for <see cref="StreakBrokenEvent"/> (raised by the Streak module) and
/// triggers a push notification via <see cref="INotificationPort"/>. The data payload
/// includes a deeplink so the Flutter app can route the tap.
/// </summary>
public class StreakBrokenNotificationHandler(INotificationPort notifications)
    : IEventHandler<StreakBrokenEvent>
{
    public async Task HandleAsync(StreakBrokenEvent e, CancellationToken ct = default)
    {
        await notifications.SendToUserAsync(
            userId: e.UserId,
            category: "streak-broken",
            title: "Your streak ended \uD83D\uDC94",
            body: $"Your {e.PreviousStreak}-day streak just broke. Start a new one today.",
            data: new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://home"
            },
            isCritical: false,
            ct: ct);
    }
}
