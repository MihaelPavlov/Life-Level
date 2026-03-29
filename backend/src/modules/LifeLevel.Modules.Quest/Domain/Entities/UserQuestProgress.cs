namespace LifeLevel.Modules.Quest.Domain.Entities;

public class UserQuestProgress
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public Guid QuestId { get; set; }
    public Quest Quest { get; set; } = null!;
    public double CurrentValue { get; set; }
    public bool IsCompleted { get; set; }
    public bool RewardClaimed { get; set; }
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public bool BonusAwarded { get; set; }
}
