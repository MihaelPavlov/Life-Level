using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.WorldZone.Application.EventHandlers;

public class LevelUpRegionAvailabilityHandler(
    DbContext db,
    ILevelUpReceiptPort receipts) : IEventHandler<CharacterLeveledUpEvent>
{
    public async Task HandleAsync(CharacterLeveledUpEvent e, CancellationToken ct = default)
    {
        var regions = await db.Set<Domain.Entities.Region>()
            .Where(r => r.LevelRequirement > e.PreviousLevel
                        && r.LevelRequirement <= e.NewLevel)
            .OrderBy(r => r.LevelRequirement)
            .Select(r => new LevelUpRegionInfo(
                r.Id, r.Name, r.Emoji, r.LevelRequirement))
            .ToListAsync(ct);
        await receipts.AddRegionsAsync(e.ReceiptId, regions, ct);
    }
}
