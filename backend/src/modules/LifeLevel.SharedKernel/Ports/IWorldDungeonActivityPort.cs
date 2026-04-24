using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Result returned from <see cref="IWorldDungeonActivityPort.CreditActivityAsync"/>
/// when an activity actually advanced a dungeon floor. Callers use this to
/// animate the floor-clear and (if <see cref="RunCompleted"/>) celebrate the
/// bonus XP award.
/// </summary>
public record FloorCreditResult(
    Guid DungeonZoneId,
    string DungeonName,
    int ClearedFloorOrdinal,
    int TotalFloors,
    bool RunCompleted,
    int BonusXpAwarded);

/// <summary>
/// Port exposed by the WorldZone module so the Activity pipeline can credit
/// real-world workouts against the user's active dungeon floor. Returns null
/// when the activity didn't match (no active run, wrong activity type, or
/// progress accumulated without clearing the floor).
/// </summary>
public interface IWorldDungeonActivityPort
{
    Task<FloorCreditResult?> CreditActivityAsync(
        Guid userId,
        ActivityType type,
        double distanceKm,
        int durationMinutes,
        CancellationToken ct = default);
}
