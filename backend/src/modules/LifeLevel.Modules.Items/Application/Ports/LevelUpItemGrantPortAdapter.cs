using LifeLevel.Modules.Items.Application.UseCases;
using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Items.Application.Ports;

public class LevelUpItemGrantPortAdapter(ItemGrantService itemGrantService) : ILevelUpItemGrantPort
{
    public async Task<IReadOnlyList<GrantedItemInfo>> EvaluateAndGrantAsync(
        Guid userId, int previousLevel, int newLevel, CancellationToken ct = default)
    {
        var summary = await itemGrantService.EvaluateLevelUpAsync(userId, previousLevel, newLevel, ct);
        return summary.Granted
            .Select(i => new GrantedItemInfo(i.Id, i.Name, i.Icon, i.Rarity, i.SlotType))
            .ToList();
    }
}
