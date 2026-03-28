using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Domain.Entities;

public class Character
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    // Progression
    public int Level { get; set; } = 1;
    public long Xp { get; set; } = 0;
    public CharacterRank Rank { get; set; } = CharacterRank.Novice;

    // Core stats
    public int Strength { get; set; } = 0;   // STR — gym/weightlifting
    public int Endurance { get; set; } = 0;  // END — running/cycling
    public int Agility { get; set; } = 0;    // AGI — running/cycling
    public int Flexibility { get; set; } = 0; // FLX — yoga/stretching
    public int Stamina { get; set; } = 0;    // STA — all activities

    public int AvailableStatPoints { get; set; } = 0;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Guid? ClassId { get; set; }
    public CharacterClass? Class { get; set; }
    public string? AvatarEmoji { get; set; }
    public bool IsSetupComplete { get; set; } = false;

    public ICollection<Activity> Activities { get; set; } = [];
}
