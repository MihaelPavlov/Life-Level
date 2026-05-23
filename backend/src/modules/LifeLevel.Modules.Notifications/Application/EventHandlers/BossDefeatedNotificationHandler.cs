using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Notifications.Application.EventHandlers;

/// <summary>
/// Listens for <see cref="BossDefeatedEvent"/> (raised by the Adventure module) and
/// triggers a push notification via <see cref="INotificationPort"/>.
/// </summary>
public class BossDefeatedNotificationHandler(INotificationPort notifications)
    : IEventHandler<BossDefeatedEvent>
{
    public async Task HandleAsync(BossDefeatedEvent e, CancellationToken ct = default)
    {
        await notifications.SendToUserAsync(
            userId: e.UserId,
            category: "boss-defeated",
            title: "🏆 Boss Defeated!",
            body: "You defeated the boss. Rewards have been added to your account.",
            data: new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://boss"
            },
            isCritical: true,
            ct: ct);
    }
}
