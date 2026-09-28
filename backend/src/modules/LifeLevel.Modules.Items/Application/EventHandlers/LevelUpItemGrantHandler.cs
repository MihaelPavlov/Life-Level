using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Items.Application.EventHandlers;

public class LevelUpItemGrantHandler(
    ItemGrantService itemGrant,
    ILevelUpReceiptPort receipts) : IEventHandler<CharacterLeveledUpEvent>
{
    public async Task HandleAsync(CharacterLeveledUpEvent e, CancellationToken ct = default)
    {
        var result = await itemGrant.EvaluateLevelUpAsync(
            e.UserId, e.PreviousLevel, e.NewLevel, ct);
        await receipts.AddItemsAsync(
            e.ReceiptId,
            result.Granted.Select(i => new GrantedItemInfo(
                i.Id, i.Name, i.Icon, i.Rarity, i.SlotType)).ToList(),
            result.Blocked.Select(i => new LevelUpBlockedItemInfo(
                i.ItemId, i.ItemName, i.ItemIcon)).ToList(),
            ct);
    }
}
