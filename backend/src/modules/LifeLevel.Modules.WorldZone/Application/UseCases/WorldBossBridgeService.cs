using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Modules.WorldZone.Application.UseCases;

/// <summary>
/// Bridges a world-zone boss (WorldZone with Type = Boss) to the legacy
/// Encounters Boss entity so the existing BossScreen / damage pipeline can
/// be reused. Spawns a Boss row lazily when the user arrives at a boss zone
/// and wires a per-user UserBossState via <see cref="IBossSpawnPort"/>.
///
/// Idempotent — repeated calls return the same Boss id and don't duplicate
/// either the Boss row or the UserBossState row.
/// </summary>
public class WorldBossBridgeService(DbContext db, IBossSpawnPort bossSpawn)
{
    private const string ForestWardenIcon = "assets/Bosses/boss_forest_warden.svg";

    /// <summary>
    /// Ensure a legacy Boss row exists for <paramref name="worldZoneId"/>
    /// (must be a Boss-type zone) and that the user has a UserBossState
    /// attached. Returns the Boss id.
    /// </summary>
    public async Task<Guid> EnsureSpawnedAsync(Guid userId, Guid worldZoneId, CancellationToken ct = default)
    {
        var zone = await db.Set<WorldZoneEntity>()
            .Include(z => z.Region)
            .FirstOrDefaultAsync(z => z.Id == worldZoneId, ct)
            ?? throw new InvalidOperationException("Zone not found.");

        if (!zone.IsBoss && zone.Type != WorldZoneType.Boss)
            throw new InvalidOperationException("Not a boss zone.");

        // Idempotent — if a Boss row already exists for this zone, reuse it.
        // Also refresh TimerDays/SuppressExpiry from the zone so seed-time
        // changes (e.g. "Forest Warden now has a 2-day timer") propagate to
        // users who already triggered a spawn before the change.
        var existingBoss = await db.Set<Boss>()
            .FirstOrDefaultAsync(b => b.WorldZoneId == worldZoneId, ct);
        if (existingBoss != null)
        {
            var zoneSuppress = zone.BossSuppressExpiry ?? true;
            var zoneTimerDays = zone.BossTimerDays ?? 0;
            var zoneIcon = GetBossIcon(zone);
            if (existingBoss.SuppressExpiry != zoneSuppress
                || existingBoss.TimerDays != zoneTimerDays
                || existingBoss.Icon != zoneIcon)
            {
                existingBoss.SuppressExpiry = zoneSuppress;
                existingBoss.TimerDays = zoneTimerDays;
                existingBoss.Icon = zoneIcon;
                await db.SaveChangesAsync(ct);
            }
            await bossSpawn.EnsureUserStateAsync(userId, existingBoss.Id, ct);
            return existingBoss.Id;
        }

        // First-time spawn for this world-zone boss. HP scales with region
        // chapter index and zone tier; reward XP inherits the zone's reward.
        var hp = ComputeBossHp(zone.Region.ChapterIndex, zone.Tier);

        // Per-zone timer: defaults to "no timeout" (SuppressExpiry=true, TimerDays=0)
        // when either field is null on the zone. Set both on a Boss-type zone to
        // enforce an N-day expiry (e.g. Forest Warden → 2 days).
        var suppressExpiry = zone.BossSuppressExpiry ?? true;
        var timerDays = zone.BossTimerDays ?? 0;

        var boss = new Boss
        {
            Id = Guid.NewGuid(),
            // NodeId left null — world-zone bosses aren't tied to the old local map.
            NodeId = null,
            Name = zone.Name,
            Icon = GetBossIcon(zone),
            MaxHp = hp,
            RewardXp = zone.XpReward,
            TimerDays = timerDays,
            IsMini = false,
            WorldZoneId = worldZoneId,
            SuppressExpiry = suppressExpiry,
        };

        db.Set<Boss>().Add(boss);
        await db.SaveChangesAsync(ct);
        await bossSpawn.EnsureUserStateAsync(userId, boss.Id, ct);
        return boss.Id;
    }

    /// <summary>
    /// World-zone boss HP formula. Tuned in one place so it's easy to adjust.
    /// </summary>
    private static int ComputeBossHp(int chapterIndex, int tier)
        => 500 * Math.Max(chapterIndex, 1) + 250 * Math.Max(tier, 1);

    private static string GetBossIcon(WorldZoneEntity zone)
        => string.Equals(zone.Name, "Forest Warden", StringComparison.OrdinalIgnoreCase)
            ? ForestWardenIcon
            : zone.Emoji;

    public async Task<Guid> EnsureTrailBlockerSpawnedAsync(
        Guid userId,
        Guid trailEncounterTemplateId,
        CancellationToken ct = default)
    {
        var template = await db.Set<TrailEncounterTemplate>()
            .FirstOrDefaultAsync(t => t.Id == trailEncounterTemplateId, ct)
            ?? throw new InvalidOperationException("Trail encounter not found.");

        if (template.Type != "blocker")
            throw new InvalidOperationException("Trail encounter is not a blocker.");

        var config = JsonSerializer.Deserialize<JsonElement>(template.ConfigJson);
        var maxHp = config.TryGetProperty("maxHp", out var hpEl) ? hpEl.GetInt32() : 1000;
        var retreatDays = config.TryGetProperty("retreatDays", out var retreatEl) ? retreatEl.GetInt32() : 1;
        var rewardXp = config.TryGetProperty("rewardXp", out var rewardEl)
            ? rewardEl.GetInt32()
            : Math.Max(100, maxHp / 4);
        var normalizedHp = Math.Max(1, maxHp);
        var normalizedTimerDays = Math.Max(1, retreatDays);

        var existingBoss = await db.Set<Boss>()
            .FirstOrDefaultAsync(b => b.TrailEncounterTemplateId == trailEncounterTemplateId, ct);
        if (existingBoss != null)
        {
            var changed = false;
            if (existingBoss.MaxHp != normalizedHp)
            {
                existingBoss.MaxHp = normalizedHp;
                changed = true;
            }
            if (existingBoss.RewardXp != rewardXp)
            {
                existingBoss.RewardXp = rewardXp;
                changed = true;
            }
            if (existingBoss.TimerDays != normalizedTimerDays)
            {
                existingBoss.TimerDays = normalizedTimerDays;
                changed = true;
            }
            if (existingBoss.SuppressExpiry)
            {
                existingBoss.SuppressExpiry = false;
                changed = true;
            }
            if (changed) await db.SaveChangesAsync(ct);
            await bossSpawn.EnsureUserStateAsync(userId, existingBoss.Id, ct);
            return existingBoss.Id;
        }

        var boss = new Boss
        {
            Id = Guid.NewGuid(),
            NodeId = null,
            Name = template.Name,
            Icon = string.IsNullOrWhiteSpace(template.Emoji) ? "💀" : template.Emoji,
            MaxHp = normalizedHp,
            RewardXp = rewardXp,
            TimerDays = normalizedTimerDays,
            IsMini = false,
            WorldZoneId = null,
            TrailEncounterTemplateId = trailEncounterTemplateId,
            SuppressExpiry = false,
        };

        db.Set<Boss>().Add(boss);
        await db.SaveChangesAsync(ct);
        await bossSpawn.EnsureUserStateAsync(userId, boss.Id, ct);
        return boss.Id;
    }
}
