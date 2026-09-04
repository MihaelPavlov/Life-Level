namespace LifeLevel.Modules.Character.Application.DTOs;

public record AvatarOptionResponse(
    string Emoji,
    string Name,
    bool IsUnlocked,
    bool IsEquipped,
    string? UnlockRequirement,
    int SortOrder);

public record UpdateAvatarRequest(string AvatarEmoji);
