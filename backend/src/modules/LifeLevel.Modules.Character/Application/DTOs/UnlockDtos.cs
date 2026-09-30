namespace LifeLevel.Modules.Character.Application.DTOs;

/// <summary>A feature in the unlock chain and where the player is with it.</summary>
public record UnlockDto(
    string Key,
    int Order,
    bool Unlocked,
    DateTime? UnlockedAt,
    bool Seen,
    bool Toured);

public record UnlocksResponse(List<UnlockDto> Unlocks);

public record UnlockTouredResponse(string Key, long XpAwarded);
