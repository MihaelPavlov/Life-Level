using LifeLevel.Api.Application.DTOs.Quest;
using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Application.DTOs.Activity;

public class LogActivityRequest
{
    public ActivityType Type { get; set; }
    public int DurationMinutes { get; set; }
    public double? DistanceKm { get; set; }
    public int? Calories { get; set; }
    public int? HeartRateAvg { get; set; }
}

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
    public List<UserQuestProgressDto> CompletedQuests { get; set; } = new();
    public bool StreakUpdated { get; set; }
    public int CurrentStreak { get; set; }
    public bool AllDailyQuestsCompleted { get; set; }
    public int BonusXpAwarded { get; set; }
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
    public DateTime LoggedAt { get; set; }
}
