namespace LifeLevel.Modules.WorldZone.Domain.Enums;

/// <summary>
/// Lifecycle state of a user's dungeon run. Stored on UserWorldDungeonState.
/// </summary>
public enum DungeonRunStatus
{
    NotEntered = 0,
    InProgress = 1,
    Completed = 2,
    Abandoned = 3
}
