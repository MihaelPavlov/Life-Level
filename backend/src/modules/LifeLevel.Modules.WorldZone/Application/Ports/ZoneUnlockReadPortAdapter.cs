using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.WorldZone.Application.Ports;

public class ZoneUnlockReadPortAdapter(DbContext db) : IZoneUnlockReadPort
{
    public async Task<IReadOnlyList<UnlockedZoneInfo>> GetZonesUnlockedInRangeAsync(
        int previousLevel, int newLevel, CancellationToken ct = default)
    {
        if (newLevel <= previousLevel) return [];

        return await db.Set<Domain.Entities.WorldZone>()
            .Where(z => z.LevelRequirement > previousLevel
                        && z.LevelRequirement <= newLevel)
            .OrderBy(z => z.LevelRequirement)
            .Select(z => new UnlockedZoneInfo(
                z.Id, z.Name, z.Emoji, z.Region.Name, z.LevelRequirement))
            .ToListAsync(ct);
    }
}
