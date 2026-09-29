using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.SharedKernel.Ports;

/// <summary>Base XP and stat gains a workout would give, before gear, talent and class bonuses.</summary>
public record ActivityGainPreview(int Xp, int Strength, int Endurance, int Agility, int Flexibility, int Stamina);

/// <summary>
/// Lets other modules show what a workout is worth without logging it, e.g. the
/// pending-workout review sheet. Pure calculation, no side effects.
/// </summary>
public interface IActivityGainPreviewPort
{
    ActivityGainPreview Preview(ActivityType type, int durationMinutes, double? distanceKm, int? calories);
}
