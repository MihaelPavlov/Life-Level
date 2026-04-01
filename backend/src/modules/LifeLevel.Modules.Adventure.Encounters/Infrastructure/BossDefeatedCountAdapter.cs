using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure;

public class BossDefeatedCountAdapter(DbContext db) : IBossDefeatedCountReadPort
{
    public Task<int> GetDefeatedCountAsync(Guid userId, CancellationToken ct = default)
    {
        return db.Set<UserBossState>()
            .CountAsync(s => s.UserId == userId && s.IsDefeated, ct);
    }
}
