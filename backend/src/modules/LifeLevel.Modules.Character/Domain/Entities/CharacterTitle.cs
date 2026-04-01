namespace LifeLevel.Modules.Character.Domain.Entities;

public class CharacterTitle
{
    public Guid Id { get; set; }
    public Guid CharacterId { get; set; }
    public Character Character { get; set; } = null!;
    public Guid TitleId { get; set; }
    public Title Title { get; set; } = null!;
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
}
