using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure;

/// <summary>
/// Adapter for <see cref="IBossSpawnPort"/>. Creates a per-user UserBossState
/// row for a spawned Boss, idempotently. Used by the WorldZone module's
/// bridge service when a world-zone boss is lazily spawned on arrival.
/// </summary>
public class BossSpawnAdapter(DbContext db) : IBossSpawnPort
{
    public async Task EnsureUserStateAsync(Guid userId, Guid bossId, CancellationToken ct = default)
    {
        var boss = await db.Set<Boss>().FindAsync([bossId], ct)
            ?? throw new InvalidOperationException("Boss not found.");

        var existing = await db.Set<UserBossState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BossId == bossId, ct);
        if (existing != null) return;

        // World-zone bosses skip the local-map progress link. Legacy local-map
        // bosses still get the progress link populated when available so
        // existing list-view code keeps working.
        Guid? userMapProgressId = null;
        if (!boss.WorldZoneId.HasValue)
        {
            var progress = await db.Set<UserMapProgress>()
                .FirstOrDefaultAsync(p => p.UserId == userId, ct);
            userMapProgressId = progress?.Id;
        }

        db.Set<UserBossState>().Add(new UserBossState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            BossId = bossId,
            UserMapProgressId = userMapProgressId,
            HpDealt = 0,
            IsDefeated = false,
            IsExpired = false,
            StartedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync(ct);
    }
}
