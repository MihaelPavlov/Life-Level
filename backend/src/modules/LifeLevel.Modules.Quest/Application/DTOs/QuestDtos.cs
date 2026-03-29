using LifeLevel.Modules.Quest.Domain.Enums;

namespace LifeLevel.Modules.Quest.Application.DTOs;

public class UserQuestProgressDto
{
    public Guid Id { get; set; }
    public Guid QuestId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? RequiredActivity { get; set; }
    public double TargetValue { get; set; }
    public double CurrentValue { get; set; }
    public string TargetUnit { get; set; } = string.Empty;
    public long RewardXp { get; set; }
    public bool IsCompleted { get; set; }
    public bool RewardClaimed { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class QuestProgressUpdateResult
{
    public List<UserQuestProgressDto> UpdatedQuests { get; set; } = new();
    public bool AllDailyCompleted { get; set; }
    public int BonusXpAwarded { get; set; }
}
