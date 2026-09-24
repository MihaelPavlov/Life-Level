using LifeLevel.Modules.Quest.Application.UseCases;
using LifeLevel.Modules.Quest.Domain.Enums;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Quest.Application.EventHandlers;

public sealed class QuestGameProgressHandler(QuestService quests) :
    IEventHandler<ZoneCompletedEvent>,
    IEventHandler<ChestOpenedEvent>,
    IEventHandler<BossContributionEvent>,
    IEventHandler<BossDefeatedEvent>,
    IEventHandler<GuildRaidContributionEvent>,
    IEventHandler<GuildRaidWonEvent>,
    IEventHandler<RegionCompletedEvent>
{
    public Task HandleAsync(ZoneCompletedEvent e, CancellationToken ct = default) =>
        quests.UpdateProgressFromGameEventAsync(e.UserId, QuestCategory.ZonesCompleted, ct: ct);

    public Task HandleAsync(ChestOpenedEvent e, CancellationToken ct = default) =>
        quests.UpdateProgressFromGameEventAsync(e.UserId, QuestCategory.ChestsOpened, ct: ct);

    public Task HandleAsync(BossContributionEvent e, CancellationToken ct = default) =>
        quests.UpdateProgressFromGameEventAsync(e.UserId, QuestCategory.BossContributions, ct: ct);

    public Task HandleAsync(BossDefeatedEvent e, CancellationToken ct = default) =>
        quests.UpdateProgressFromGameEventAsync(e.UserId, QuestCategory.BossesDefeated, ct: ct);

    public Task HandleAsync(GuildRaidContributionEvent e, CancellationToken ct = default) =>
        quests.UpdateProgressFromGameEventAsync(e.UserId, QuestCategory.GuildRaidContributions, ct: ct);

    public Task HandleAsync(GuildRaidWonEvent e, CancellationToken ct = default) =>
        quests.UpdateProgressFromGameEventAsync(e.UserId, QuestCategory.GuildRaidsWon, ct: ct);

    public Task HandleAsync(RegionCompletedEvent e, CancellationToken ct = default) =>
        quests.UpdateProgressFromGameEventAsync(e.UserId, QuestCategory.RegionsCompleted, ct: ct);
}
