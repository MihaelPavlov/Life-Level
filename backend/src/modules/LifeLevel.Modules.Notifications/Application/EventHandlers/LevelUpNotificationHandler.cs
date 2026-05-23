using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Notifications.Application.EventHandlers;

/// <summary>
/// Listens for <see cref="CharacterLeveledUpEvent"/> (raised by the Character module) and
/// triggers a push notification via <see cref="INotificationPort"/>.
/// </summary>
public class LevelUpNotificationHandler(INotificationPort notifications)
    : IEventHandler<CharacterLeveledUpEvent>
{
    public async Task HandleAsync(CharacterLeveledUpEvent e, CancellationToken ct = default)
    {
        await notifications.SendToUserAsync(
            userId: e.UserId,
            category: "level-up",
            title: "🎉 Level Up!",
            body: $"You reached Level {e.NewLevel}. New zones unlocked!",
            data: new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://home"
            },
            isCritical: true,
            ct: ct);
    }
}
