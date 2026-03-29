namespace LifeLevel.Modules.WorldZone.Domain.Entities;

public class World
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<WorldZone> Zones { get; set; } = [];
    public ICollection<UserWorldProgress> UserProgresses { get; set; } = [];
}
