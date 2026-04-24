using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure;

public class BossDefeatAdapter(DbContext db) : IBossDefeatReadPort
{
    public async Task<HashSet<Guid>> GetDefeatedWorldZoneIdsAsync(Guid userId, CancellationToken ct = default)
    {
        var ids = await db.Set<UserBossState>()
            .Where(s => s.UserId == userId && s.IsDefeated)
            .Join(db.Set<Boss>(),
                  s => s.BossId,
                  b => b.Id,
                  (s, b) => b.WorldZoneId)
            .Where(z => z != null)
            .Select(z => z!.Value)
            .ToListAsync(ct);
        return ids.ToHashSet();
    }
}
