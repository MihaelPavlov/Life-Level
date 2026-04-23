using LifeLevel.Modules.WorldZone.Domain.Enums;

namespace LifeLevel.Modules.WorldZone.Domain.Entities;

public class Region
{
    public Guid Id { get; set; }
    public Guid WorldId { get; set; }
    public World World { get; set; } = null!;
    public string Name { get; set; } = "";
    public string Emoji { get; set; } = "";
    public RegionTheme Theme { get; set; }
    public int ChapterIndex { get; set; }
    public int LevelRequirement { get; set; } = 1;
    public string Lore { get; set; } = "";

    public string BossName { get; set; } = "";
    public RegionBossStatus BossStatus { get; set; } = RegionBossStatus.Locked;
    public RegionStatus DefaultStatus { get; set; } = RegionStatus.Locked;

    /// <summary>
    /// JSON-serialized list of <see cref="RegionPin"/>. Rendered as banner chips on the
    /// World screen hero card. Stored as a string column for schema simplicity — regions
    /// rarely change and pin count is always small (≤ 2).
    /// </summary>
    public string PinsJson { get; set; } = "[]";

    public List<WorldZone> Zones { get; set; } = [];
}

public sealed record RegionPin(string Label, string Value);
