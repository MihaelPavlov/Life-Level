namespace LifeLevel.Modules.WorldZone.Application.DTOs;

public class WorldZoneDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Icon { get; set; } = string.Empty;
    public string Region { get; set; } = string.Empty;
    public int Tier { get; set; }
    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public int LevelRequirement { get; set; }
    public int TotalXp { get; set; }
    public double TotalDistanceKm { get; set; }
    public bool IsCrossroads { get; set; }
    public bool IsStartZone { get; set; }
    public int NodeCount { get; set; }  // Will be 0 after module extraction (MapNode is in different module)
    public ZoneUserStateDto? UserState { get; set; }
}

public class ZoneUserStateDto
{
    public bool IsUnlocked { get; set; }
    public bool IsLevelMet { get; set; }
    public bool IsCurrentZone { get; set; }
    public bool IsDestination { get; set; }
}

public class WorldZoneEdgeDto
{
    public Guid Id { get; set; }
    public Guid FromZoneId { get; set; }
    public Guid ToZoneId { get; set; }
    public double DistanceKm { get; set; }
    public bool IsBidirectional { get; set; }
}

public class WorldFullResponse
{
    public List<WorldZoneDto> Zones { get; set; } = [];
    public List<WorldZoneEdgeDto> Edges { get; set; } = [];
    public UserWorldProgressDto UserProgress { get; set; } = null!;
    public int CharacterLevel { get; set; }
}

public class UserWorldProgressDto
{
    public Guid CurrentZoneId { get; set; }
    public Guid? CurrentEdgeId { get; set; }
    public double DistanceTraveledOnEdge { get; set; }
    public Guid? DestinationZoneId { get; set; }
    public List<Guid> UnlockedZoneIds { get; set; } = [];
}

public class SetWorldDestinationRequest
{
    public Guid DestinationZoneId { get; set; }
}

public class DebugAddWorldDistanceRequest
{
    public double Km { get; set; }
}

public class CompleteZoneResult
{
    public string ZoneName { get; set; } = string.Empty;
    public string ZoneIcon { get; set; } = string.Empty;
    public int XpAwarded { get; set; }
    public bool AlreadyCompleted { get; set; }
}
