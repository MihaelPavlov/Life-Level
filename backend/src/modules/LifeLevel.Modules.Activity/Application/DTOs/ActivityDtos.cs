using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Activity.Application.DTOs;

public class LogActivityRequest
{
    public ActivityType Type { get; set; }
    public int DurationMinutes { get; set; }
    public double? DistanceKm { get; set; }
    public int? Calories { get; set; }
    public int? HeartRateAvg { get; set; }
}

public record BlockedItemInfo(string ItemName, string ItemIcon);

public class LogActivityResult
{
    public Guid ActivityId { get; set; }
    public int XpGained { get; set; }
    public int StrGained { get; set; }
    public int EndGained { get; set; }
    public int AgiGained { get; set; }
    public int FlxGained { get; set; }
    public int StaGained { get; set; }
    public bool LeveledUp { get; set; }
    public int? NewLevel { get; set; }
    public IReadOnlyList<CompletedQuestInfo> CompletedQuests { get; set; } = [];
    public bool StreakUpdated { get; set; }
    public int CurrentStreak { get; set; }
    public bool AllDailyQuestsCompleted { get; set; }
    public int BonusXpAwarded { get; set; }
    public int XpBonusApplied { get; init; } = 0;
    public IReadOnlyList<BlockedItemInfo> BlockedItems { get; init; } = [];
    public LevelUpUnlocksDto? LevelUpUnlocks { get; init; }
}

public class ActivityHistoryDto
{
    public Guid Id { get; set; }
    public string Type { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public double DistanceKm { get; set; }
    public int Calories { get; set; }
    public int? HeartRateAvg { get; set; }
    public long XpGained { get; set; }
    public int StrGained { get; set; }
    public int EndGained { get; set; }
    public int AgiGained { get; set; }
    public int FlxGained { get; set; }
    public int StaGained { get; set; }
    public int Steps { get; set; }
    public DateTime LoggedAt { get; set; }
}
