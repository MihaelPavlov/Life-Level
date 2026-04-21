using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Character.Application.DTOs;

public record CharacterProfileContext(
    string Username,
    WeeklyActivityStatsDto WeeklyStats,
    StreakReadDto? Streak,
    bool HasClaimedLoginRewardToday,
    int DailyQuestsCompleted
);

public record CharacterProfileResponse(
    string? Username,
    string? AvatarEmoji,
    string? ClassName,
    string? ClassEmoji,
    string Rank,
    int Level,
    long Xp,
    long XpForCurrentLevel,
    long XpForNextLevel,
    int Strength,
    int Endurance,
    int Agility,
    int Flexibility,
    int Stamina,
    int WeeklyRuns,
    double WeeklyDistanceKm,
    long WeeklyXpEarned,
    int CurrentStreak,
    int AvailableStatPoints,
    int LongestStreak,
    int ShieldsAvailable,
    int DailyQuestsCompleted,
    bool LoginRewardAvailable,
    int TutorialStep,
    int TutorialTopicsSeen,
    GearBonuses? GearBonuses = null
);
