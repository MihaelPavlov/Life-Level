namespace LifeLevel.Api.Application.DTOs.Map;

public class MapNodeDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Icon { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Region { get; set; } = string.Empty;
    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public int LevelRequirement { get; set; }
    public bool IsStartNode { get; set; }
    public bool IsHidden { get; set; }
    public int RewardXp { get; set; }

    // Object data (only one will be populated based on Type)
    public BossDto? Boss { get; set; }
    public ChestDto? Chest { get; set; }
    public DungeonPortalDto? DungeonPortal { get; set; }
    public CrossroadsDto? Crossroads { get; set; }

    // Per-user state
    public NodeUserStateDto? UserState { get; set; }
}

public class BossDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public int MaxHp { get; set; }
    public int RewardXp { get; set; }
    public int TimerDays { get; set; }
    public bool IsMini { get; set; }
    // User state
    public int HpDealt { get; set; }
    public bool IsDefeated { get; set; }
    public bool IsExpired { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? TimerExpiresAt { get; set; }
    public DateTime? DefeatedAt { get; set; }
}

public class ChestDto
{
    public Guid Id { get; set; }
    public string Rarity { get; set; } = string.Empty;
    public int RewardXp { get; set; }
    public bool IsCollected { get; set; }
}

public class DungeonPortalDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int TotalFloors { get; set; }
    public int CurrentFloor { get; set; }
    public bool IsDiscovered { get; set; }
    public List<DungeonFloorDto> Floors { get; set; } = [];
}

public class DungeonFloorDto
{
    public int FloorNumber { get; set; }
    public string RequiredActivity { get; set; } = string.Empty;
    public int RequiredMinutes { get; set; }
    public int RewardXp { get; set; }
}

public class CrossroadsDto
{
    public Guid Id { get; set; }
    public List<CrossroadsPathDto> Paths { get; set; } = [];
    public Guid? ChosenPathId { get; set; }
}

public class CrossroadsPathDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public double DistanceKm { get; set; }
    public string Difficulty { get; set; } = string.Empty;
    public int EstimatedDays { get; set; }
    public int RewardXp { get; set; }
    public string? AdditionalRequirement { get; set; }
    public Guid? LeadsToNodeId { get; set; }
}

public class NodeUserStateDto
{
    public bool IsUnlocked { get; set; }   // visited
    public bool IsLevelMet { get; set; }   // character.Level >= node.LevelRequirement
    public bool IsCurrentNode { get; set; }
    public bool IsDestination { get; set; }
}
