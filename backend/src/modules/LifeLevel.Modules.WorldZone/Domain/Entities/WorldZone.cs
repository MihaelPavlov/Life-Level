using LifeLevel.Modules.WorldZone.Domain.Enums;

namespace LifeLevel.Modules.WorldZone.Domain.Entities;

public class WorldZone
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Emoji { get; set; } = string.Empty;
    public int Tier { get; set; }
    public int LevelRequirement { get; set; } = 1;
    public int XpReward { get; set; } = 0;
    public double DistanceKm { get; set; } = 0;
    public bool IsStartZone { get; set; } = false;
    public bool IsBoss { get; set; } = false;
    public WorldZoneType Type { get; set; } = WorldZoneType.Entry;

    // Zone-level progress/lore counters (nullable so unconfigured zones stay null).
    public int? LoreTotal { get; set; }
    public int? LoreCollected { get; set; }
    public int? NodesTotal { get; set; }
    public int? NodesCompleted { get; set; }

    // Chest zones (Type == Chest): inline reward metadata. Null for all other zones.
    public int? ChestRewardXp { get; set; }
    public string? ChestRewardDescription { get; set; }

    // Dungeon zones (Type == Dungeon): inline bonus XP granted on run completion.
    // Floor definitions live in WorldZoneDungeonFloor keyed by WorldZoneId. Null
    // for all other zones.
    public int? DungeonBonusXp { get; set; }

    public Guid RegionId { get; set; }
    public Region Region { get; set; } = null!;

    // When non-null, this zone is a branch of a specific Crossroads zone.
    // Two branches sharing the same BranchOfId form the fork pair for that crossroads.
    // Plain Entry/Standard/Boss zones leave this null.
    public Guid? BranchOfId { get; set; }

    public ICollection<WorldZoneEdge> EdgesFrom { get; set; } = [];
    public ICollection<WorldZoneEdge> EdgesTo { get; set; } = [];
    public ICollection<UserZoneUnlock> UnlockedByUsers { get; set; } = [];
}
