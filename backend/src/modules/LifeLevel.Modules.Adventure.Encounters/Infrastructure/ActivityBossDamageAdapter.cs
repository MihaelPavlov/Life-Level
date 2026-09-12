using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure;

/// <summary>
/// Adapter for <see cref="IActivityBossDamagePort"/>. Finds every non-defeated
/// <see cref="UserBossState"/> the user has and applies workout-derived damage
/// to each. Uses the existing <c>BossService.CalculateDamageFromActivity</c>
/// formula + <c>BossService.DealDamageAsync</c> so boss death triggers the
/// same defeat pipeline (including the world-zone completion hook).
/// </summary>
public class ActivityBossDamageAdapter(
    DbContext db,
    BossService bossService,
    ILogger<ActivityBossDamageAdapter>? logger = null,
    ITalentBonusReadPort? talentBonus = null,
    ICharacterCombatStatsReadPort? combatStats = null) : IActivityBossDamagePort
{
    public async Task<IReadOnlyList<BossDefeatedInfo>> ApplyAsync(
        Guid userId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        DateTime activityLoggedAt,
        CancellationToken ct = default)
    {
        var log = logger ?? NullLogger<ActivityBossDamageAdapter>.Instance;

        var activeStates = await db.Set<UserBossState>()
            .Where(s => s.UserId == userId
                        && !s.IsDefeated
                        && !s.IsExpired
                        && (!s.StartedAt.HasValue || s.StartedAt.Value <= activityLoggedAt))
            .ToListAsync(ct);

        var activeBossIds = activeStates.Select(s => s.BossId).ToList();
        if (activeBossIds.Count == 0) return Array.Empty<BossDefeatedInfo>();

        var damage = BossService.CalculateDamageFromActivity(
            activityType, durationMinutes, distanceKm, calories);
        if (damage <= 0) return Array.Empty<BossDefeatedInfo>();

        // Power-based multiplier (Attack/Defense/Health, including the
        // permanent talent BossDamagePct baked into Attack — see
        // CombatStatsCalculator). Applied before the still-separate,
        // contextual BossActiveDamagePct below, which only fires because a
        // boss is active here by definition.
        if (combatStats is not null)
        {
            var stats = await combatStats.GetCombatStatsAsync(userId, ct);
            damage = (int)Math.Round(damage * stats.DamageMultiplier);
        }

        if (talentBonus is not null)
        {
            var talents = await talentBonus.GetBonusesAsync(userId, ct);
            if (talents.BossActiveDamagePct > 0)
                damage = (int)Math.Round(damage * (1.0 + talents.BossActiveDamagePct / 100.0));
        }

        // Single bulk lookup keyed by id — avoids N+1 when multiple bosses
        // are defeated in the same tick.
        var bossesById = await db.Set<Boss>()
            .Where(b => activeBossIds.Contains(b.Id))
            .ToDictionaryAsync(b => b.Id, ct);

        var defeated = new List<BossDefeatedInfo>();

        foreach (var bossId in activeBossIds)
        {
            try
            {
                var result = await bossService.DealDamageAsync(userId, bossId, damage);
                if (result.JustDefeated && bossesById.TryGetValue(bossId, out var boss))
                {
                    defeated.Add(new BossDefeatedInfo(
                        BossId: boss.Id,
                        Name: boss.Name,
                        Icon: boss.Icon,
                        RewardXp: result.RewardXpAwarded > 0 ? result.RewardXpAwarded : boss.RewardXp,
                        IsMini: boss.IsMini));
                }
            }
            catch (Exception ex)
            {
                // Swallow — a stale legacy boss state shouldn't break the
                // activity-log flow for the user. Log and continue so other
                // active bosses still get the damage. Do NOT add to the
                // defeated list since we don't know whether it died.
                log.LogWarning(ex,
                    "ActivityBossDamage SKIP user={UserId} boss={BossId} damage={Damage}",
                    userId, bossId, damage);
            }
        }

        return defeated;
    }
}
