namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Lightweight payload describing a boss that was just defeated by an
/// activity-log call. Surfaced back to the caller (Activity module) so it
/// can include the info in <c>LogActivityResult</c> and the mobile client
/// can show a celebratory popup.
/// </summary>
public record BossDefeatedInfo(Guid BossId, string Name, string Icon, int RewardXp, bool IsMini);

public record BossCombatTurnInfo(
    Guid BossId,
    string BossName,
    int RawDamage,
    int DamageDealt,
    int BossHpAfter,
    int BossMaxHp,
    int DamageTaken,
    int PlayerHpAfter,
    int PlayerMaxHp,
    bool BossDefeated,
    bool PlayerDefeated,
    string? SkipReason,
    DateTime? RecoveryEndsAt);

public record ActivityBossDamageResult(
    BossCombatTurnInfo? CombatTurn,
    IReadOnlyList<BossDefeatedInfo> BossDefeats)
{
    public static readonly ActivityBossDamageResult Empty = new(null, []);
}

/// <summary>
/// Cross-module hook for one workout turn against the targeted personal boss.
///
/// Damage is computed from the activity shape (type + duration + distance +
/// calories) via the existing <c>BossService.CalculateDamageFromActivity</c>
/// formula. The optional position was captured before the workout moved the
/// player and can start an unstarted world-zone boss if no fight is active.
///
/// Returns the bosses (if any) that were killed by this single damage tick,
/// so the activity-log response can carry a "you defeated X" payload.
/// Returns an empty list when nothing was defeated.
/// </summary>
public interface IActivityBossDamagePort
{
    Task<ActivityBossDamageResult> ApplyAsync(
        Guid userId,
        Guid activityId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        DateTime activityLoggedAt,
        CancellationToken ct = default,
        WorldBossPosition? bossPositionAtStart = null,
        bool allowAutomaticStart = true);
}
