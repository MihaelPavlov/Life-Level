namespace LifeLevel.Api.Application.DTOs.Character;

public record CharacterSetupResponse(
    Guid CharacterId,
    string ClassName,
    string ClassEmoji,
    string AvatarEmoji,
    long Xp,
    int Level,
    bool IsSetupComplete
);
