namespace LifeLevel.Modules.Achievements.Domain.Entities;

public class UserAchievement
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid AchievementId { get; set; }
    public Achievement Achievement { get; set; } = null!;
    public double CurrentValue { get; set; }
    public DateTime? UnlockedAt { get; set; }
    public bool IsUnlocked => UnlockedAt.HasValue;
}
