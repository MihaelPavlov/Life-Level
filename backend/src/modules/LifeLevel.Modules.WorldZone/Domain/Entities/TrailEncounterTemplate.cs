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

    /// Optional: pin this encounter to a specific edge (by zone pair).
    /// When both are null the encounter is placed randomly across region edges.
    public Guid? PinnedFromZoneId { get; set; }
    public Guid? PinnedToZoneId { get; set; }

    /// Optional fixed position on the edge (0.0 = start, 1.0 = end).
    /// When null, a deterministic seed-based position (0.25–0.75) is used.
    public double? PositionFraction { get; set; }
}
