namespace LifeLevel.Modules.Character.Application.DTOs;

public record CharacterSetupResponse(
    Guid CharacterId,
    string ClassName,
    string ClassEmoji,
    string AvatarEmoji,
    long Xp,
    int Level,
    bool IsSetupComplete
);
