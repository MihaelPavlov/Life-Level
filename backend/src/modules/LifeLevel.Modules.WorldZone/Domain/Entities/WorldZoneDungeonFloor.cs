using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.WorldZone.Domain.Entities;

/// <summary>
/// A single floor inside a dungeon zone. Keyed by WorldZoneId; ordered by
/// Ordinal (1..N). The activity type + target value define what real-world
/// workout clears the floor.
/// </summary>
public class WorldZoneDungeonFloor
{
    public Guid Id { get; set; }
    public Guid WorldZoneId { get; set; }

    /// <summary>1-based. Floors are cleared in ordinal order.</summary>
    public int Ordinal { get; set; }

    /// <summary>Activity type required to credit progress to this floor.</summary>
    public ActivityType ActivityType { get; set; }

    public DungeonFloorTargetKind TargetKind { get; set; }

    /// <summary>Target in km (when TargetKind = DistanceKm) or minutes (when TargetKind = DurationMinutes).</summary>
    public double TargetValue { get; set; }

    public string Name { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
}
