namespace LifeLevel.Modules.WorldZone.Domain.Entities;

public class TrailEncounterTemplate
{
    public Guid Id { get; set; }
    public Guid RegionId { get; set; }
    public Region Region { get; set; } = null!;
    public string Type { get; set; } = "";        // "story" | "merchant" | "blocker"
    public string Name { get; set; } = "";
    public string Emoji { get; set; } = "";
    public double SpawnChance { get; set; } = 0.5;
    public bool IsActive { get; set; } = true;
    public string ConfigJson { get; set; } = "{}";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
