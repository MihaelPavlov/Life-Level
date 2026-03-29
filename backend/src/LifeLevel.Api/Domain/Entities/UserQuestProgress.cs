namespace LifeLevel.Api.Domain.Entities;

public class UserQuestProgress
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public Guid QuestId { get; set; }
    public Quest Quest { get; set; } = null!;
    public decimal CurrentValue { get; set; }
    public bool IsCompleted { get; set; }
    public bool RewardClaimed { get; set; }
    public DateTime AssignedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public bool BonusAwarded { get; set; }  // all-5-daily bonus tracker
}
