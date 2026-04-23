namespace LifeLevel.Modules.WorldZone.Application.DTOs;

// Existing DTOs — still used by the legacy /api/world/full endpoint while
// Flutter migrates to /api/map/world + /api/map/region/{id}. Field names match
// the post-rename WorldZone entity (Emoji, XpReward, DistanceKm).

public class WorldZoneDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Emoji { get; set; } = string.Empty;
    public Guid RegionId { get; set; }
    public string Region { get; set; } = string.Empty; // region name
    public int Tier { get; set; }
    public int LevelRequirement { get; set; }
    public int XpReward { get; set; }
    public double DistanceKm { get; set; }
    public bool IsStartZone { get; set; }
    public bool IsBoss { get; set; }
    public string Type { get; set; } = string.Empty; // lowercase WorldZoneType name
    public int NodeCount { get; set; }
    public int CompletedNodeCount { get; set; }
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
    public Guid? CurrentRegionId { get; set; }
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
    public string ZoneEmoji { get; set; } = string.Empty;
    public int XpAwarded { get; set; }
    public bool AlreadyCompleted { get; set; }
}
