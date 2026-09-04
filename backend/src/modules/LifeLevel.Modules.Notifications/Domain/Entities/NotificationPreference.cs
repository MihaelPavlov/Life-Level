namespace LifeLevel.Modules.Notifications.Domain.Entities;

public class NotificationPreference
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public bool PushEnabled { get; set; } = true;
    public bool LevelUpEnabled { get; set; } = true;
    public bool QuestEnabled { get; set; } = true;
    public bool BossEnabled { get; set; } = true;
    public bool StreakEnabled { get; set; } = true;
    public bool RankEnabled { get; set; } = true;
    public bool QuietHoursEnabled { get; set; } = true;
    public int QuietHoursStartUtc { get; set; } = 22;
    public int QuietHoursEndUtc { get; set; } = 8;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
