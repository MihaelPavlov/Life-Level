using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Notifications.Application.EventHandlers;

/// <summary>
/// Listens for <see cref="CharacterRankChangedEvent"/> (raised by the Character module) and
/// triggers a push notification via <see cref="INotificationPort"/>.
/// </summary>
public class RankChangedNotificationHandler(INotificationPort notifications)
    : IEventHandler<CharacterRankChangedEvent>
{
    public async Task HandleAsync(CharacterRankChangedEvent e, CancellationToken ct = default)
    {
        await notifications.SendToUserAsync(
            userId: e.UserId,
            category: "rank-changed",
            title: "⬆️ Rank Up!",
            body: $"You are now a {e.NewRank}. The world recognizes your power.",
            data: new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://profile"
            },
            isCritical: true,
            ct: ct);
    }
}
