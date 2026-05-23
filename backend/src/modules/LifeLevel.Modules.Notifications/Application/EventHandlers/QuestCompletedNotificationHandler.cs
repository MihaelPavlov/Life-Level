using LifeLevel.Modules.Quest.Domain.Events;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Notifications.Application.EventHandlers;

/// <summary>
/// Listens for <see cref="QuestCompletedEvent"/> (raised by the Quest module) and
/// triggers a push notification via <see cref="INotificationPort"/>.
/// </summary>
public class QuestCompletedNotificationHandler(INotificationPort notifications)
    : IEventHandler<QuestCompletedEvent>
{
    public async Task HandleAsync(QuestCompletedEvent e, CancellationToken ct = default)
    {
        await notifications.SendToUserAsync(
            userId: e.UserId,
            category: "quest-completed",
            title: "🎯 Quest Complete!",
            body: $"'{e.QuestTitle}' done. +{e.RewardXp} XP earned.",
            data: new Dictionary<string, string>
            {
                ["deeplink"] = "lifelevel://quests"
            },
            isCritical: false,
            ct: ct);
    }
}
