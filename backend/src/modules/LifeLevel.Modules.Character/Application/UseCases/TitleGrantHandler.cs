using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Character.Application.UseCases;

public class TitleGrantHandler(TitleService titles) :
    IEventHandler<BossDefeatedEvent>,
    IEventHandler<CharacterRankChangedEvent>,
    IEventHandler<ActivityLoggedEvent>
{
    public Task HandleAsync(BossDefeatedEvent e, CancellationToken ct) =>
        titles.CheckAndGrantTitlesAsync(e.UserId, ct);

    public Task HandleAsync(CharacterRankChangedEvent e, CancellationToken ct) =>
        titles.CheckAndGrantTitlesAsync(e.UserId, ct);

    public Task HandleAsync(ActivityLoggedEvent e, CancellationToken ct) =>
        titles.CheckAndGrantTitlesAsync(e.UserId, ct);
}
