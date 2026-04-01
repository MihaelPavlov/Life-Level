using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.SharedKernel.Events;

namespace LifeLevel.Modules.Items.Application;

public class LevelUpItemAwardHandler(ItemGrantService itemGrantService) : IEventHandler<CharacterLeveledUpEvent>
{
    public async Task HandleAsync(CharacterLeveledUpEvent e, CancellationToken ct = default)
    {
        // Blocked items are surfaced via LogActivityResult.BlockedItems — discard here
        await itemGrantService.EvaluateLevelUpAsync(e.UserId, e.PreviousLevel, e.NewLevel, ct);
    }
}
