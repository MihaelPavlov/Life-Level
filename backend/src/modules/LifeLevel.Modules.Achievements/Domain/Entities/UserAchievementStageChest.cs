using LifeLevel.Modules.Achievements.Domain.Enums;

namespace LifeLevel.Modules.Achievements.Domain.Entities;

/// <summary>
/// A stage chest the user opened. A stage is one category + tier of a Reward Road;
/// its chest opens once, after every achievement in the stage is claimed.
/// </summary>
public class UserAchievementStageChest
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public AchievementCategory Category { get; set; }
    public AchievementTier Tier { get; set; }
    public DateTime OpenedAt { get; set; }
    public Guid? ItemId { get; set; }
    public int Coins { get; set; }
    public int Gems { get; set; }
}
