using LifeLevel.Modules.Quest.Domain.Enums;

namespace LifeLevel.Modules.Quest.Application.DTOs;

public class UserQuestProgressDto
{
    public Guid Id { get; set; }
    public Guid QuestId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? RequiredActivity { get; set; }
    public double TargetValue { get; set; }
    public double CurrentValue { get; set; }
    public string TargetUnit { get; set; } = string.Empty;
    public long RewardXp { get; set; }
    public int RewardCoins { get; set; }
    public int RewardCrystals { get; set; }
    public int RewardPoints { get; set; }
    public bool IsCompleted { get; set; }
    public bool RewardClaimed { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public record TaskMilestoneRewardDto(int Coins, int Crystals, int Xp, int Shields);

public record TaskMilestoneDto(
    int Threshold,
    TaskMilestoneRewardDto Reward,
    bool IsUnlocked,
    bool IsClaimed);

public record TaskRewardPeriodDto(
    string Period,
    DateTime PeriodStartUtc,
    DateTime ResetAtUtc,
    int PointsEarned,
    int PointsMaximum,
    IReadOnlyList<TaskMilestoneDto> Milestones,
    IReadOnlyList<UserQuestProgressDto> Tasks);

public record TaskMilestoneClaimResult(
    string Period,
    int Threshold,
    TaskMilestoneRewardDto Reward,
    TaskRewardPeriodDto UpdatedPeriod);

public class QuestProgressUpdateResult
{
    public List<UserQuestProgressDto> UpdatedQuests { get; set; } = new();
    public bool AllDailyCompleted { get; set; }
    public int BonusXpAwarded { get; set; }
}
