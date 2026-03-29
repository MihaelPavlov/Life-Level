namespace LifeLevel.Api.Application.DTOs.Character;

public record CharacterProfileResponse(
    // Identity
    string Username,
    string? AvatarEmoji,
    string? ClassName,
    string? ClassEmoji,
    string Rank,

    // Progression
    int Level,
    long Xp,
    long XpForCurrentLevel,   // total XP at start of current level
    long XpForNextLevel,      // total XP at start of next level

    // Core stats
    int Strength,
    int Endurance,
    int Agility,
    int Flexibility,
    int Stamina,

    // This week
    int WeeklyRuns,
    double WeeklyDistanceKm,
    long WeeklyXpEarned,
    int CurrentStreak,
    int AvailableStatPoints,

    // Phase 2 — streak & login
    int LongestStreak,
    int ShieldsAvailable,
    int DailyQuestsCompleted,
    bool LoginRewardAvailable
);
