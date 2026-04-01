namespace LifeLevel.Modules.Achievements.Application.DTOs;

public record AchievementDto(
    Guid Id,
    string Title,
    string Description,
    string Icon,
    string Category,
    string Tier,
    long XpReward,
    double TargetValue,
    string TargetUnit,
    double CurrentValue,
    bool IsUnlocked,
    DateTime? UnlockedAt
);

public record CheckUnlocksResult(List<Guid> NewlyUnlockedIds);
