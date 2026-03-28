namespace LifeLevel.Api.Application.DTOs.CharacterClass;

public record CharacterClassResponse(
    Guid Id,
    string Name,
    string Emoji,
    string Description,
    string Tagline,
    float StrMultiplier,
    float EndMultiplier,
    float AgiMultiplier,
    float FlxMultiplier,
    float StaMultiplier
);
