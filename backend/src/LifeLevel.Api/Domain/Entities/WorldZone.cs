namespace LifeLevel.Api.Domain.Entities;

public class WorldZone
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Icon { get; set; } = string.Empty;
    public string Region { get; set; } = string.Empty;
    public int Tier { get; set; }
    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public int LevelRequirement { get; set; } = 1;
    public int TotalXp { get; set; } = 0;
    public double TotalDistanceKm { get; set; } = 0;
    public bool IsCrossroads { get; set; } = false;
    public bool IsStartZone { get; set; } = false;
    public bool IsHidden { get; set; } = false;

    public Guid WorldId { get; set; }
    public World World { get; set; } = null!;

    public ICollection<WorldZoneEdge> EdgesFrom { get; set; } = [];
    public ICollection<WorldZoneEdge> EdgesTo { get; set; } = [];
    public ICollection<MapNode> Nodes { get; set; } = [];
    public ICollection<UserZoneUnlock> UnlockedByUsers { get; set; } = [];
}
