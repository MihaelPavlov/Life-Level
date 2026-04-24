using LifeLevel.Modules.WorldZone.Domain.Enums;

namespace LifeLevel.Modules.WorldZone.Domain.Entities;

/// <summary>
/// A user's run through a dungeon zone. Unique per (UserId, WorldZoneId).
/// Created on <c>EnterAsync</c>, advanced as the user clears floors, and
/// transitions to <c>Abandoned</c> when the user moves off a dungeon zone
/// before completing the run.
/// </summary>
public class UserWorldDungeonState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid WorldZoneId { get; set; }

    public DungeonRunStatus Status { get; set; } = DungeonRunStatus.NotEntered;

    /// <summary>
    /// 0 = not in any floor (before Enter), 1..N = current active floor ordinal.
    /// </summary>
    public int CurrentFloorOrdinal { get; set; }

    public DateTime? StartedAt { get; set; }
    public DateTime? FinishedAt { get; set; }
}
