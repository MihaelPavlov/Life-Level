namespace LifeLevel.SharedKernel.Ports;

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
/// </summary>
public interface IActivityBossDamagePort
{
    Task ApplyAsync(
        Guid userId,
        string activityType,
        int durationMinutes,
        double distanceKm,
        int calories,
        CancellationToken ct = default);
}
