namespace LifeLevel.Modules.Character.Domain.Entities;

public class CharacterClass
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Tagline { get; set; } = string.Empty;

    public float StrMultiplier { get; set; } = 1.0f;
    public float EndMultiplier { get; set; } = 1.0f;
    public float AgiMultiplier { get; set; } = 1.0f;
    public float FlxMultiplier { get; set; } = 1.0f;
    public float StaMultiplier { get; set; } = 1.0f;

    public bool IsActive { get; set; } = true;
}
