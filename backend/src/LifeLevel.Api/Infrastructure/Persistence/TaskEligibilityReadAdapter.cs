using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Guild.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public sealed class TaskEligibilityReadAdapter(AppDbContext db) : ITaskEligibilityReadPort
{
    public async Task<TaskEligibilitySnapshot> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var progress = await db.Set<UserWorldProgress>().AsNoTracking()
            .FirstOrDefaultAsync(p => p.UserId == userId, ct);

        var hasZone = progress?.DestinationZoneId != null;
        var unopenedChests = 0;
        var currentZoneIsBoss = false;
        if (progress?.CurrentRegionId is Guid regionId)
        {
            var opened = db.Set<UserWorldChestState>().AsNoTracking()
                .Where(s => s.UserId == userId).Select(s => s.WorldZoneId);
            unopenedChests = await db.Set<WorldZone>().AsNoTracking()
                .CountAsync(z => z.RegionId == regionId && z.Type == WorldZoneType.Chest && !opened.Contains(z.Id), ct);
            currentZoneIsBoss = await db.Set<WorldZone>().AsNoTracking()
                .AnyAsync(z => z.Id == progress.CurrentZoneId && (z.IsBoss || z.Type == WorldZoneType.Boss), ct);
        }

        var activeBoss = await db.Set<UserBossState>().AsNoTracking()
            .AnyAsync(s => s.UserId == userId && !s.IsDefeated && !s.IsExpired, ct);

        var guildId = await db.Set<GuildMember>().AsNoTracking()
            .Where(m => m.UserId == userId).Select(m => (Guid?)m.GuildId).FirstOrDefaultAsync(ct);
        var activeRaid = guildId.HasValue && await db.Set<GuildRaid>().AsNoTracking()
            .AnyAsync(r => r.GuildId == guildId && !r.IsDefeated && !r.IsExpired && r.ExpiresAt > DateTime.UtcNow, ct);

        return new(hasZone, unopenedChests, activeBoss, activeRaid, currentZoneIsBoss && activeBoss);
    }
}
