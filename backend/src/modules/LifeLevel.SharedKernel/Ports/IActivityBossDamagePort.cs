namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Lightweight payload describing a boss that was just defeated by an
/// activity-log call. Surfaced back to the caller (Activity module) so it
/// can include the info in <c>LogActivityResult</c> and the mobile client
/// can show a celebratory popup.
/// </summary>
public record BossDefeatedInfo(Guid BossId, string Name, string Icon, int RewardXp, bool IsMini);

/// <summary>
/// Cross-module hook: when an activity is logged in the Activity module,
/// this port distributes "automatic" damage to every active boss the user
/// is fighting. Implemented in <c>LifeLevel.Modules.Adventure.Encounters</c>
/// so ActivityService doesn't take a hard dep on the Boss entity.
///
/// Damage is computed from the activity shape (type + duration + distance +
/// calories) via the existing <c>BossService.CalculateDamageFromActivity</c>
/// formula. A single workout damages every non-defeated boss the user has
/// an active <c>UserBossState</c> for.
///
/// Returns the bosses (if any) that were killed by this single damage tick,
/// so the activity-log response can carry a "you defeated X" payload.
/// Returns an empty list when nothing was defeated.
/// </summary>
public interface IActivityBossDamagePort
{
    Task<IReadOnlyList<BossDefeatedInfo>> ApplyAsync(
        Guid userId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        DateTime activityLoggedAt,
        CancellationToken ct = default);
}
