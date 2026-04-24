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
    ILogger<ActivityBossDamageAdapter>? logger = null) : IActivityBossDamagePort
{
    public async Task ApplyAsync(
        Guid userId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        CancellationToken ct = default)
    {
        var log = logger ?? NullLogger<ActivityBossDamageAdapter>.Instance;

        var activeBossIds = await db.Set<UserBossState>()
            .Where(s => s.UserId == userId && !s.IsDefeated && !s.IsExpired)
            .Select(s => s.BossId)
            .ToListAsync(ct);

        if (activeBossIds.Count == 0) return;

        var damage = BossService.CalculateDamageFromActivity(
            activityType, durationMinutes, distanceKm, calories);
        if (damage <= 0) return;

        foreach (var bossId in activeBossIds)
        {
            try
            {
                await bossService.DealDamageAsync(userId, bossId, damage);
            }
            catch (Exception ex)
            {
                // Swallow — a stale legacy boss state shouldn't break the
                // activity-log flow for the user. Log and continue so other
                // active bosses still get the damage.
                log.LogWarning(ex,
                    "ActivityBossDamage SKIP user={UserId} boss={BossId} damage={Damage}",
                    userId, bossId, damage);
            }
        }
    }
}
