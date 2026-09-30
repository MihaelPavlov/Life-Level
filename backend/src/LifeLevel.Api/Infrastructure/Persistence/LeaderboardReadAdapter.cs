using LifeLevel.Modules.Activity.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Guild.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Streak.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;
using XpHistoryEntry = LifeLevel.Modules.Character.Domain.Entities.XpHistoryEntry;

namespace LifeLevel.Api.Infrastructure.Persistence;

/// <summary>
/// Reads leaderboard scores from the modules that own them: weekly XP, km and
/// boss damage, current streak, and power (all-time, from combat stats).
/// </summary>
public sealed class LeaderboardReadAdapter(
    AppDbContext db, ICharacterCombatStatsReadPort combat, IMemoryCache cache) : ILeaderboardReadPort
{
    private static readonly TimeSpan PowerCacheTtl = TimeSpan.FromMinutes(5);

    public async Task<LeaderboardPool> GetPoolAsync(
        Guid viewerId, LeaderboardScope scope, LeaderboardMetric metric,
        DateTime weekStartUtc, CancellationToken ct = default)
    {
        List<Guid>? members = null;
        string? context = null;
        switch (scope)
        {
            case LeaderboardScope.Region:
            {
                var region = await db.Set<UserWorldProgress>().AsNoTracking()
                    .Where(p => p.UserId == viewerId)
                    .Select(p => new { p.CurrentZone.RegionId, p.CurrentZone.Region.Name })
                    .FirstOrDefaultAsync(ct);
                if (region == null) return new LeaderboardPool(false, null, []);
                context = region.Name;
                members = await db.Set<UserWorldProgress>().AsNoTracking()
                    .Where(p => p.CurrentZone.RegionId == region.RegionId)
                    .Select(p => p.UserId).ToListAsync(ct);
                break;
            }
            case LeaderboardScope.Guild:
            {
                var guild = await db.Set<GuildMember>().AsNoTracking()
                    .Where(m => m.UserId == viewerId)
                    .Select(m => new { m.GuildId, m.Guild.Name })
                    .FirstOrDefaultAsync(ct);
                if (guild == null) return new LeaderboardPool(false, null, []);
                context = guild.Name;
                members = await db.Set<GuildMember>().AsNoTracking()
                    .Where(m => m.GuildId == guild.GuildId)
                    .Select(m => m.UserId).ToListAsync(ct);
                break;
            }
        }

        var characters = db.Set<CharacterEntity>().AsNoTracking().Where(c => c.IsSetupComplete);
        if (members != null) characters = characters.Where(c => members.Contains(c.UserId));
        var rows = await (
            from c in characters
            join u in db.Set<User>().AsNoTracking() on c.UserId equals u.Id
            select new
            {
                CharacterId = c.Id, c.UserId, u.Username, c.AvatarEmoji, c.Level,
                ClassName = c.Class != null ? c.Class.Name : null,
            }).ToListAsync(ct);
        if (rows.Count == 0) return new LeaderboardPool(true, context, []);

        var characterIds = rows.Select(r => r.CharacterId).ToList();
        var userIds = rows.Select(r => r.UserId).ToList();
        Dictionary<Guid, double> byCharacter = [];
        Dictionary<Guid, double> byUser = [];

        switch (metric)
        {
            case LeaderboardMetric.Xp:
                byCharacter = await db.Set<XpHistoryEntry>().AsNoTracking()
                    .Where(x => x.EarnedAt >= weekStartUtc && characterIds.Contains(x.CharacterId))
                    .GroupBy(x => x.CharacterId)
                    .Select(g => new { g.Key, Total = g.Sum(x => x.Xp) })
                    .ToDictionaryAsync(x => x.Key, x => (double)x.Total, ct);
                break;
            case LeaderboardMetric.Km:
                byCharacter = await db.Set<Activity>().AsNoTracking()
                    .Where(a => a.LoggedAt >= weekStartUtc && characterIds.Contains(a.CharacterId))
                    .GroupBy(a => a.CharacterId)
                    .Select(g => new { g.Key, Total = g.Sum(a => a.DistanceKm) })
                    .ToDictionaryAsync(x => x.Key, x => Math.Round(x.Total, 1, MidpointRounding.AwayFromZero), ct);
                break;
            case LeaderboardMetric.Boss:
                byUser = await (
                    from t in db.Set<BossCombatTurn>().AsNoTracking()
                    join s in db.Set<UserBossState>().AsNoTracking() on t.UserBossStateId equals s.Id
                    where t.OccurredAt >= weekStartUtc && userIds.Contains(s.UserId)
                    group t by s.UserId into g
                    select new { g.Key, Total = g.Sum(t => t.DamageDealt) })
                    .ToDictionaryAsync(x => x.Key, x => (double)x.Total, ct);
                break;
            case LeaderboardMetric.Streak:
                byUser = await db.Set<Streak>().AsNoTracking()
                    .Where(s => userIds.Contains(s.UserId))
                    .ToDictionaryAsync(s => s.UserId, s => (double)s.Current, ct);
                break;
            case LeaderboardMetric.Power:
                foreach (var id in userIds) byUser[id] = await PowerAsync(id, ct);
                break;
        }

        var entries = rows.Select(r => new LeaderboardCandidate(
            r.UserId, r.Username, r.AvatarEmoji, r.Level, r.ClassName,
            byCharacter.GetValueOrDefault(r.CharacterId) + byUser.GetValueOrDefault(r.UserId))).ToList();
        return new LeaderboardPool(true, context, entries);
    }

    // Power needs gear, talents and bosses per player, so it is cached briefly.
    private async Task<double> PowerAsync(Guid userId, CancellationToken ct) =>
        await cache.GetOrCreateAsync($"leaderboard:power:{userId}", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = PowerCacheTtl;
            return (double)(await combat.GetCombatStatsAsync(userId, ct)).Power;
        });
}
