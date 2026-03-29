using LifeLevel.Modules.Character.Domain.Enums;

namespace LifeLevel.Modules.Character.Domain.Entities;

public class Character
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    public int Level { get; set; } = 1;
    public long Xp { get; set; } = 0;
    public CharacterRank Rank { get; set; } = CharacterRank.Novice;

    public int Strength { get; set; } = 0;
    public int Endurance { get; set; } = 0;
    public int Agility { get; set; } = 0;
    public int Flexibility { get; set; } = 0;
    public int Stamina { get; set; } = 0;

    public int AvailableStatPoints { get; set; } = 0;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Guid? ClassId { get; set; }
    public CharacterClass? Class { get; set; }
    public string? AvatarEmoji { get; set; }
    public bool IsSetupComplete { get; set; } = false;
}
