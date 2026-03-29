using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Domain.Entities;

public class MapNode
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Icon { get; set; } = string.Empty;
    public MapNodeType Type { get; set; }
    public MapRegion Region { get; set; }
    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public int LevelRequirement { get; set; } = 1;
    public int RewardXp { get; set; } = 0;
    public bool IsStartNode { get; set; } = false;
    public bool IsHidden { get; set; } = false;

    public Guid? WorldZoneId { get; set; }
    public WorldZone? WorldZone { get; set; }

    public ICollection<MapEdge> EdgesFrom { get; set; } = [];
    public ICollection<MapEdge> EdgesTo { get; set; } = [];
    public Boss? Boss { get; set; }
    public Chest? Chest { get; set; }
    public DungeonPortal? DungeonPortal { get; set; }
    public Crossroads? Crossroads { get; set; }
}
