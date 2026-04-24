using LifeLevel.Modules.WorldZone.Domain.Enums;

namespace LifeLevel.Modules.WorldZone.Domain.Entities;

/// <summary>
/// A user's progress on a single dungeon floor. Unique per (UserId, FloorId).
/// Created for every floor of a dungeon when the user enters the run: Floor 1
/// starts Active, remaining floors start Locked.
/// </summary>
public class UserWorldDungeonFloorState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid FloorId { get; set; }

    public DungeonFloorStatus Status { get; set; } = DungeonFloorStatus.Locked;

    /// <summary>Cumulative km or minutes, capped at the floor's TargetValue.</summary>
    public double ProgressValue { get; set; }

    public DateTime? CompletedAt { get; set; }
}
