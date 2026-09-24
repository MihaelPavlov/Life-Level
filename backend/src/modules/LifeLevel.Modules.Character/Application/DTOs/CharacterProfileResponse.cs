using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Character.Application.DTOs;

public record CharacterProfileContext(
    string Username,
    WeeklyActivityStatsDto WeeklyStats,
    StreakReadDto? Streak,
    int DailyQuestsCompleted,
    int BossesDefeated = 0
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
    int TutorialStep,
    int TutorialTopicsSeen,
    int MapTutorialStep,
    GearBonuses? GearBonuses = null,
    TalentSummaryDto? Talents = null,
    int Attack = 0,
    int Defense = 0,
    int Health = 0,
    int Power = 0
);
