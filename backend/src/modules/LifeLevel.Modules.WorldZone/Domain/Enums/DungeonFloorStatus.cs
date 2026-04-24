namespace LifeLevel.Modules.WorldZone.Domain.Enums;

/// <summary>
/// Lifecycle state of a single floor within a dungeon run. Stored on
/// UserWorldDungeonFloorState.
/// </summary>
public enum DungeonFloorStatus
{
    Locked = 0,
    Active = 1,
    Completed = 2,
    Forfeited = 3
}
