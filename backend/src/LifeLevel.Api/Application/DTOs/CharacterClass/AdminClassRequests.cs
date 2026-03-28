namespace LifeLevel.Api.Application.DTOs.CharacterClass;

public record CreateClassRequest(
    string Name, string Emoji, string Description, string Tagline,
    float StrMultiplier, float EndMultiplier, float AgiMultiplier,
    float FlxMultiplier, float StaMultiplier);

public record UpdateClassRequest(
    string Name, string Emoji, string Description, string Tagline,
    float StrMultiplier, float EndMultiplier, float AgiMultiplier,
    float FlxMultiplier, float StaMultiplier, bool IsActive);
