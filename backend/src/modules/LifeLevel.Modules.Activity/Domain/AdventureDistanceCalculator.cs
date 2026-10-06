using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.Activity.Domain;

/// <summary>
/// Converts real-world workout distance into the normalized distance used by
/// world-map travel. All other activity systems continue to use real distance.
/// </summary>
public static class AdventureDistanceCalculator
{
    public static double GetMultiplier(ActivityType type) => type switch
    {
        ActivityType.Running => 1.0,
        ActivityType.Walking => 1.0,
        ActivityType.Hiking => 1.0,
        ActivityType.Cycling => 0.25,
        ActivityType.Swimming => 4.0,
        ActivityType.Gym or ActivityType.Yoga or ActivityType.Climbing => 0.0,
        _ => 0.0,
    };

    public static double Calculate(ActivityType type, double? realDistanceKm)
    {
        if (realDistanceKm is null or <= 0) return 0;
        return realDistanceKm.Value * GetMultiplier(type);
    }
}
