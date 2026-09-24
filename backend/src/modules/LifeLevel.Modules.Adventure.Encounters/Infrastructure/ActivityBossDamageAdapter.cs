using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.SharedKernel.Calculators;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure;

/// <summary>
/// Resolves one workout into one turn against the user's targeted personal boss.
/// The complete input/output snapshot is persisted so history never changes when
/// the player's equipment, talents, or stats change later.
/// </summary>
public class ActivityBossDamageAdapter(
    DbContext db,
    BossService bossService,
    ILogger<ActivityBossDamageAdapter>? logger = null,
    ITalentBonusReadPort? talentBonus = null,
    ICharacterCombatStatsReadPort? combatStats = null,
    IEventPublisher? events = null,
    IConfiguration? configuration = null) : IActivityBossDamagePort
{
    public async Task<ActivityBossDamageResult> ApplyAsync(
        Guid userId,
        Guid activityId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        DateTime activityLoggedAt,
        CancellationToken ct = default)
    {
        var log = logger ?? NullLogger<ActivityBossDamageAdapter>.Instance;
        var v2Enabled = !bool.TryParse(
            configuration?["BossCombat:V2Enabled"], out var configuredEnabled)
            || configuredEnabled;

        var stateQuery = db.Set<UserBossState>()
            .Include(s => s.Boss)
            .Where(s => s.UserId == userId
                        && !s.IsDefeated
                        && !s.IsExpired
                        && s.StartedAt.HasValue
                        && s.StartedAt.Value <= activityLoggedAt);

        var state = v2Enabled
            ? await stateQuery.Where(s => s.IsTargeted)
                .OrderByDescending(s => s.StartedAt).FirstOrDefaultAsync(ct)
            : await stateQuery.OrderByDescending(s => s.StartedAt).FirstOrDefaultAsync(ct);

        // Upgrade legacy active fights lazily. This gives existing users one
        // deterministic target without requiring a separate maintenance job.
        if (state is null && v2Enabled)
        {
            state = await stateQuery.OrderByDescending(s => s.StartedAt)
                .FirstOrDefaultAsync(ct);
            if (state is not null)
            {
                state.IsTargeted = true;
                state.MaxHpSnapshot = state.MaxHpSnapshot > 0
                    ? state.MaxHpSnapshot : state.Boss.MaxHp;
                state.ArmorSnapshot = state.Boss.Armor;
                state.CounterattackDamageSnapshot = state.Boss.CounterattackDamage;
                state.CombatVersion = BossCombatCalculator.CombatVersion;
            }
        }

        if (state is null) return ActivityBossDamageResult.Empty;

        var duplicate = await db.Set<BossCombatTurn>()
            .AnyAsync(t => t.UserBossStateId == state.Id && t.ActivityId == activityId, ct);
        if (duplicate) return ActivityBossDamageResult.Empty;

        try
        {
            var stats = combatStats is null
                ? new CombatStatsSnapshot(10, 5, 50, CombatStatsCalculator.PowerFloor, 1.0)
                : await combatStats.GetCombatStatsAsync(userId, ct);
            var talents = talentBonus is null
                ? TalentBonuses.Empty
                : await talentBonus.GetBonusesAsync(userId, ct);

            var maxBossHp = state.MaxHpSnapshot > 0 ? state.MaxHpSnapshot : state.Boss.MaxHp;
            var bossArmor = state.CombatVersion >= BossCombatCalculator.CombatVersion
                ? state.ArmorSnapshot : state.Boss.Armor;
            var bossCounterattack = state.CombatVersion >= BossCombatCalculator.CombatVersion
                ? state.CounterattackDamageSnapshot : state.Boss.CounterattackDamage;

            var turn = new BossCombatTurn
            {
                Id = Guid.NewGuid(),
                UserBossStateId = state.Id,
                ActivityId = activityId,
                ActivityType = activityType,
                DurationMinutes = durationMinutes,
                DistanceKm = distanceKm,
                Calories = calories,
                Attack = stats.Attack,
                Defense = stats.Defense,
                Health = stats.Health,
                Power = stats.Power,
                DamageMultiplier = stats.DamageMultiplier,
                BossActiveDamagePct = talents.BossActiveDamagePct,
                BossArmor = bossArmor,
                BossMitigation = BossCombatCalculator.Mitigation(bossArmor),
                BossCounterattackRaw = bossCounterattack,
                PlayerMitigation = BossCombatCalculator.Mitigation(stats.Defense),
                OccurredAt = activityLoggedAt,
            };

            if (state.RecoveryEndsAt.HasValue && state.RecoveryEndsAt.Value > activityLoggedAt)
            {
                turn.SkipReason = "PlayerRecovering";
                turn.BossHpAfter = Math.Max(0, maxBossHp - state.HpDealt);
                turn.PlayerHpAfter = Math.Max(0, state.CurrentPlayerHp);
                db.Set<BossCombatTurn>().Add(turn);
                await db.SaveChangesAsync(ct);
                return ToResult(state, turn, maxBossHp, stats.Health, []);
            }

            if (state.RecoveryEndsAt.HasValue)
            {
                state.RecoveryEndsAt = null;
                state.CurrentPlayerHp = stats.Health;
            }
            else if (state.CurrentPlayerHp <= 0)
            {
                state.CurrentPlayerHp = stats.Health;
            }
            else
            {
                state.CurrentPlayerHp = Math.Min(state.CurrentPlayerHp, stats.Health);
            }

            turn.RawWorkoutDamage = BossService.CalculateDamageFromActivity(
                activityType, durationMinutes, distanceKm, calories);
            var modifiedDamage = BossCombatCalculator.ApplyPlayerModifiers(
                turn.RawWorkoutDamage, stats.DamageMultiplier, talents.BossActiveDamagePct);
            turn.DamageDealt = turn.RawWorkoutDamage > 0
                ? BossCombatCalculator.ApplyMitigation(modifiedDamage, bossArmor)
                : 0;

            var damageResult = await bossService.DealDamageAsync(userId, state.BossId, turn.DamageDealt);
            turn.BossHpAfter = Math.Max(0, maxBossHp - damageResult.HpDealt);
            turn.BossDefeated = damageResult.IsDefeated;

            if (!turn.BossDefeated)
            {
                turn.DamageTaken = BossCombatCalculator.ApplyMitigation(bossCounterattack, stats.Defense);
                state.CurrentPlayerHp = Math.Max(0, state.CurrentPlayerHp - turn.DamageTaken);
                if (state.CurrentPlayerHp == 0)
                {
                    turn.PlayerDefeated = true;
                    state.RecoveryEndsAt = activityLoggedAt.AddHours(BossCombatCalculator.RecoveryHours);
                }
            }

            turn.PlayerHpAfter = state.CurrentPlayerHp;
            db.Set<BossCombatTurn>().Add(turn);
            await db.SaveChangesAsync(ct);

            if (events is not null)
                await events.PublishAsync(new BossContributionEvent(userId, activityId), ct);

            IReadOnlyList<BossDefeatedInfo> defeats = damageResult.JustDefeated
                ? [new BossDefeatedInfo(
                    state.Boss.Id,
                    state.Boss.Name,
                    state.Boss.Icon,
                    damageResult.RewardXpAwarded > 0 ? damageResult.RewardXpAwarded : state.Boss.RewardXp,
                    state.Boss.IsMini)]
                : [];

            return ToResult(state, turn, maxBossHp, stats.Health, defeats);
        }
        catch (Exception ex)
        {
            log.LogWarning(ex,
                "ActivityBossDamage SKIP user={UserId} boss={BossId} activity={ActivityId}",
                userId, state.BossId, activityId);
            return ActivityBossDamageResult.Empty;
        }
    }

    /// <summary>Compatibility overload for callers created before activity ids were propagated.</summary>
    public async Task<IReadOnlyList<BossDefeatedInfo>> ApplyAsync(
        Guid userId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        DateTime activityLoggedAt,
        CancellationToken ct = default) =>
        (await ApplyAsync(
            userId, Guid.NewGuid(), activityType, durationMinutes, distanceKm,
            calories, activityLoggedAt, ct)).BossDefeats;

    private static ActivityBossDamageResult ToResult(
        UserBossState state,
        BossCombatTurn turn,
        int maxBossHp,
        int maxPlayerHp,
        IReadOnlyList<BossDefeatedInfo> defeats) =>
        new(
            new BossCombatTurnInfo(
                state.BossId,
                state.Boss.Name,
                turn.RawWorkoutDamage,
                turn.DamageDealt,
                turn.BossHpAfter,
                maxBossHp,
                turn.DamageTaken,
                turn.PlayerHpAfter,
                maxPlayerHp,
                turn.BossDefeated,
                turn.PlayerDefeated,
                turn.SkipReason,
                state.RecoveryEndsAt),
            defeats);
}
