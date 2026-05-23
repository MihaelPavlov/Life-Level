using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Notifications.Application.EventHandlers;

/// <summary>
/// Listens for <see cref="ActivityLoggedEvent"/> (raised by the Activity module) and
/// triggers a push notification via <see cref="INotificationPort"/>.
/// </summary>
public class ActivityLoggedNotificationHandler(INotificationPort notifications)
    : IEventHandler<ActivityLoggedEvent>
{
    public async Task HandleAsync(ActivityLoggedEvent e, CancellationToken ct = default)
    {
        await notifications.SendToUserAsync(
            userId: e.UserId,
            category: "activity-logged",
            title: "💪 Workout Logged!",
            body: $"You earned XP from your {e.Type} session. Keep it up!",
            data: new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://home"
            },
            isCritical: false,
            ct: ct);
    }
}
