using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.Seasons.Domain;

/// <summary>
/// Flat Season-XP values — deliberately independent of the level-XP curve. Single source of
/// truth for how much the tier-progress bar moves per action.
/// </summary>
public static class SeasonXpRules
{
    public const int PerQuestComplete = 40;
    public const int PerBossDefeat = 300;

    private static int BaseFor(ActivityType t) => t switch
    {
        ActivityType.Running or ActivityType.Cycling => 120,
        ActivityType.Gym => 120,
        ActivityType.Swimming or ActivityType.Climbing => 110,
        ActivityType.Hiking => 100,
        ActivityType.Yoga => 90,
        _ => 90,
    };

    /// <summary>Season XP awarded for one logged activity.</summary>
    public static int ForActivity(ActivityType type, int durationMinutes, double distanceKm) =>
        BaseFor(type)
        + 2 * Math.Max(0, durationMinutes)
        + (int)(6 * Math.Max(0, distanceKm));
}
