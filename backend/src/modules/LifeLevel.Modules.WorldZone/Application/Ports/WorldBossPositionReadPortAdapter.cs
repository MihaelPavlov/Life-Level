using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.WorldZone.Application.Ports;

public sealed class WorldBossPositionReadPortAdapter(DbContext db) : IWorldBossPositionReadPort
{
    public async Task<WorldBossPosition?> GetCurrentBossZoneAsync(Guid userId, CancellationToken ct = default)
    {
        var progress = await db.Set<UserWorldProgress>()
            .Include(p => p.CurrentZone)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.World.IsActive, ct);
        if (progress == null || progress.CurrentEdgeId != null ||
            (!progress.CurrentZone.IsBoss && progress.CurrentZone.Type != WorldZoneType.Boss))
            return null;

        var arrivedAt = await db.Set<UserZoneUnlock>()
            .Where(u => u.UserId == userId && u.WorldZoneId == progress.CurrentZoneId)
            .Select(u => (DateTime?)u.UnlockedAt)
            .FirstOrDefaultAsync(ct);
        return arrivedAt.HasValue
            ? new WorldBossPosition(progress.CurrentZoneId, arrivedAt.Value)
            : null;
    }
}
