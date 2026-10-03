using LifeLevel.Modules.Achievements.Application.UseCases;
using LifeLevel.Modules.Character.Application.UseCases;
using LifeLevel.Modules.Quest.Domain.Events;
using LifeLevel.Modules.Streak.Domain.Events;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Api.Application.Realtime;

public sealed class AchievementProgressHandler(AchievementService achievements) :
    IEventHandler<ActivityLoggedEvent>, IEventHandler<BossDefeatedEvent>, IEventHandler<StreakBrokenEvent>
{
    public async Task HandleAsync(ActivityLoggedEvent e, CancellationToken ct) =>
        await achievements.CheckUnlocksAsync(e.UserId, ct);
    public async Task HandleAsync(BossDefeatedEvent e, CancellationToken ct) =>
        await achievements.CheckUnlocksAsync(e.UserId, ct);
    public async Task HandleAsync(StreakBrokenEvent e, CancellationToken ct) =>
        await achievements.CheckUnlocksAsync(e.UserId, ct);
}

public sealed class QuestTitleGrantHandler(TitleService titles) : IEventHandler<QuestCompletedEvent>
{
    public Task HandleAsync(QuestCompletedEvent e, CancellationToken ct) =>
        titles.CheckAndGrantTitlesAsync(e.UserId, ct);
}
