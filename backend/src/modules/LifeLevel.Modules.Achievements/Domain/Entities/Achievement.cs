using LifeLevel.Modules.Achievements.Domain.Enums;

namespace LifeLevel.Modules.Achievements.Domain.Entities;

public class Achievement
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public AchievementCategory Category { get; set; }
    public AchievementTier Tier { get; set; }
    public long XpReward { get; set; }
    public ConditionType ConditionType { get; set; }
    public double TargetValue { get; set; }
    public string TargetUnit { get; set; } = string.Empty;
}
