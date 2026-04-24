using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;

namespace LifeLevel.Modules.WorldZone.Application.UseCases;

/// <summary>
/// Dungeon run lifecycle: enter → sequentially clear floors via real-world
/// activities → complete run (bonus XP) or abandon (forfeit remaining floors).
///
/// Implements <see cref="IWorldDungeonActivityPort"/> so the Activity pipeline
/// can credit workouts against the user's active dungeon floor without
/// reaching into this module's internals.
/// </summary>
public class WorldDungeonService(DbContext db, ICharacterXpPort characterXp)
    : IWorldDungeonActivityPort
{
    // ------------------------------------------------------------------------
    // Enter
    // ------------------------------------------------------------------------

    /// <summary>
    /// Starts a dungeon run. Idempotent when an in-progress run already exists
    /// for the same (user, zone) — no duplicate state is created and no
    /// exception is thrown. Throws when the user isn't physically at the zone.
    /// </summary>
    public async Task EnterAsync(Guid userId, Guid zoneId, CancellationToken ct = default)
    {
        var zone = await db.Set<WorldZoneEntity>().FindAsync([zoneId], ct)
            ?? throw new InvalidOperationException("Zone not found.");

        if (zone.Type != WorldZoneType.Dungeon)
            throw new InvalidOperationException("Zone is not a dungeon.");

        var progress = await db.Set<UserWorldProgressEntity>()
            .FirstOrDefaultAsync(p => p.UserId == userId, ct)
            ?? throw new InvalidOperationException("Travel to the dungeon first.");

        if (progress.CurrentZoneId != zoneId)
            throw new InvalidOperationException("Travel to the dungeon first.");

        var existing = await db.Set<UserWorldDungeonState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.WorldZoneId == zoneId, ct);

        if (existing != null)
        {
            // Idempotent: already InProgress → no-op. For Completed or
            // Abandoned states we reject explicitly.
            if (existing.Status == DungeonRunStatus.InProgress) return;
            if (existing.Status == DungeonRunStatus.Completed)
                throw new InvalidOperationException("Dungeon already cleared.");
            if (existing.Status == DungeonRunStatus.Abandoned)
                throw new InvalidOperationException("Dungeon was abandoned. Re-running is not supported.");
            // NotEntered → fall through and initialize floor state below.
        }

        var floors = await db.Set<WorldZoneDungeonFloor>()
            .Where(f => f.WorldZoneId == zoneId)
            .OrderBy(f => f.Ordinal)
            .ToListAsync(ct);
        if (floors.Count == 0)
            throw new InvalidOperationException("Dungeon has no floors configured.");

        var now = DateTime.UtcNow;
        if (existing == null)
        {
            existing = new UserWorldDungeonState
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                WorldZoneId = zoneId,
                Status = DungeonRunStatus.InProgress,
                CurrentFloorOrdinal = floors[0].Ordinal,
                StartedAt = now,
            };
            db.Set<UserWorldDungeonState>().Add(existing);
        }
        else
        {
            existing.Status = DungeonRunStatus.InProgress;
            existing.CurrentFloorOrdinal = floors[0].Ordinal;
            existing.StartedAt = now;
            existing.FinishedAt = null;
        }

        foreach (var f in floors)
        {
            db.Set<UserWorldDungeonFloorState>().Add(new UserWorldDungeonFloorState
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                FloorId = f.Id,
                Status = f.Ordinal == floors[0].Ordinal ? DungeonFloorStatus.Active : DungeonFloorStatus.Locked,
                ProgressValue = 0,
            });
        }

        await db.SaveChangesAsync(ct);
    }

    // ------------------------------------------------------------------------
    // Read state
    // ------------------------------------------------------------------------

    public async Task<DungeonStateDto?> GetStateAsync(
        Guid userId, Guid zoneId, CancellationToken ct = default)
    {
        var zone = await db.Set<WorldZoneEntity>().FindAsync([zoneId], ct);
        if (zone == null || zone.Type != WorldZoneType.Dungeon) return null;

        var floors = await db.Set<WorldZoneDungeonFloor>()
            .Where(f => f.WorldZoneId == zoneId)
            .OrderBy(f => f.Ordinal)
            .ToListAsync(ct);

        var floorIds = floors.Select(f => f.Id).ToList();
        var floorStates = await db.Set<UserWorldDungeonFloorState>()
            .Where(s => s.UserId == userId && floorIds.Contains(s.FloorId))
            .ToDictionaryAsync(s => s.FloorId, ct);

        var runState = await db.Set<UserWorldDungeonState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.WorldZoneId == zoneId, ct);

        var runStatus = runState?.Status ?? DungeonRunStatus.NotEntered;
        var currentOrdinal = runState?.CurrentFloorOrdinal ?? 0;

        var floorDtos = floors.Select(f =>
        {
            floorStates.TryGetValue(f.Id, out var fs);
            var status = fs?.Status ?? DungeonFloorStatus.Locked;
            return new DungeonFloorDto(
                Id: f.Id,
                Ordinal: f.Ordinal,
                Name: f.Name,
                Emoji: f.Emoji,
                ActivityType: f.ActivityType.ToString(),
                TargetKind: f.TargetKind.ToString(),
                TargetValue: f.TargetValue,
                ProgressValue: fs?.ProgressValue ?? 0,
                Status: ToStatusString(status));
        }).ToList();

        return new DungeonStateDto(
            ZoneId: zone.Id,
            ZoneName: zone.Name,
            Status: ToRunStatusString(runStatus),
            CurrentFloorOrdinal: currentOrdinal,
            BonusXp: zone.DungeonBonusXp ?? 0,
            Floors: floorDtos);
    }

    // ------------------------------------------------------------------------
    // Abandon (forfeit)
    // ------------------------------------------------------------------------

    /// <summary>
    /// Transition an in-progress or not-entered dungeon run to Abandoned.
    /// All non-Completed floor states move to Forfeited. Returns the count
    /// of floors that were forfeited (zero if the run wasn't active).
    /// </summary>
    internal async Task<int> AbandonAsync(
        Guid userId, Guid zoneId, CancellationToken ct = default)
    {
        var runState = await db.Set<UserWorldDungeonState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.WorldZoneId == zoneId, ct);
        if (runState == null) return 0;
        if (runState.Status != DungeonRunStatus.InProgress &&
            runState.Status != DungeonRunStatus.NotEntered) return 0;

        var floors = await db.Set<WorldZoneDungeonFloor>()
            .Where(f => f.WorldZoneId == zoneId)
            .ToListAsync(ct);
        var floorIds = floors.Select(f => f.Id).ToList();

        var floorStates = await db.Set<UserWorldDungeonFloorState>()
            .Where(s => s.UserId == userId && floorIds.Contains(s.FloorId))
            .ToListAsync(ct);

        int forfeitedCount = 0;
        var now = DateTime.UtcNow;
        foreach (var fs in floorStates)
        {
            if (fs.Status != DungeonFloorStatus.Completed)
            {
                fs.Status = DungeonFloorStatus.Forfeited;
                forfeitedCount++;
            }
        }

        runState.Status = DungeonRunStatus.Abandoned;
        runState.FinishedAt = now;

        await db.SaveChangesAsync(ct);
        return forfeitedCount;
    }

    // ------------------------------------------------------------------------
    // Activity pipeline hook: IWorldDungeonActivityPort
    // ------------------------------------------------------------------------

    public async Task<FloorCreditResult?> CreditActivityAsync(
        Guid userId,
        ActivityType type,
        double distanceKm,
        int durationMinutes,
        CancellationToken ct = default)
    {
        var runState = await db.Set<UserWorldDungeonState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.Status == DungeonRunStatus.InProgress, ct);
        if (runState == null) return null;

        var activeFloor = await db.Set<WorldZoneDungeonFloor>()
            .FirstOrDefaultAsync(f =>
                f.WorldZoneId == runState.WorldZoneId &&
                f.Ordinal == runState.CurrentFloorOrdinal, ct);
        if (activeFloor == null) return null;

        // Activity-type match gate: only crediting workouts of the floor's
        // required type. No cross-type credit.
        if (activeFloor.ActivityType != type) return null;

        var floorState = await db.Set<UserWorldDungeonFloorState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.FloorId == activeFloor.Id, ct);
        if (floorState == null) return null;
        if (floorState.Status != DungeonFloorStatus.Active) return null;

        double credit = activeFloor.TargetKind == DungeonFloorTargetKind.DistanceKm
            ? distanceKm
            : durationMinutes;
        if (credit <= 0) return null;

        // Cap at TargetValue — overflow does not cascade to the next floor.
        var newProgress = Math.Min(activeFloor.TargetValue, floorState.ProgressValue + credit);
        floorState.ProgressValue = newProgress;

        if (newProgress < activeFloor.TargetValue)
        {
            // Accumulate but don't clear.
            await db.SaveChangesAsync(ct);
            return null;
        }

        // Floor cleared. Mark completed, attempt to activate next floor, or
        // finish the run if this was the final floor.
        var now = DateTime.UtcNow;
        floorState.Status = DungeonFloorStatus.Completed;
        floorState.CompletedAt = now;

        var allFloors = await db.Set<WorldZoneDungeonFloor>()
            .Where(f => f.WorldZoneId == runState.WorldZoneId)
            .OrderBy(f => f.Ordinal)
            .ToListAsync(ct);

        var nextFloor = allFloors.FirstOrDefault(f => f.Ordinal == activeFloor.Ordinal + 1);
        bool runCompleted = false;
        int bonusXp = 0;

        if (nextFloor == null)
        {
            // Final floor cleared — finish the run and award bonus XP.
            runState.Status = DungeonRunStatus.Completed;
            runState.FinishedAt = now;

            var zone = await db.Set<WorldZoneEntity>().FindAsync([runState.WorldZoneId], ct);
            bonusXp = zone?.DungeonBonusXp ?? 0;
            runCompleted = true;

            await db.SaveChangesAsync(ct);

            if (bonusXp > 0 && zone != null)
            {
                await characterXp.AwardXpAsync(
                    userId, "DungeonClear", "🏆", $"Cleared {zone.Name}", bonusXp, ct);
            }

            return new FloorCreditResult(
                DungeonZoneId: runState.WorldZoneId,
                DungeonName: zone?.Name ?? string.Empty,
                ClearedFloorOrdinal: activeFloor.Ordinal,
                TotalFloors: allFloors.Count,
                RunCompleted: true,
                BonusXpAwarded: bonusXp);
        }

        // Activate next floor.
        runState.CurrentFloorOrdinal = nextFloor.Ordinal;
        var nextFloorState = await db.Set<UserWorldDungeonFloorState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.FloorId == nextFloor.Id, ct);
        if (nextFloorState != null && nextFloorState.Status == DungeonFloorStatus.Locked)
        {
            nextFloorState.Status = DungeonFloorStatus.Active;
        }

        await db.SaveChangesAsync(ct);

        // Read zone name for the response.
        var dungeonZone = await db.Set<WorldZoneEntity>().FindAsync([runState.WorldZoneId], ct);

        return new FloorCreditResult(
            DungeonZoneId: runState.WorldZoneId,
            DungeonName: dungeonZone?.Name ?? string.Empty,
            ClearedFloorOrdinal: activeFloor.Ordinal,
            TotalFloors: allFloors.Count,
            RunCompleted: false,
            BonusXpAwarded: 0);
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private static string ToStatusString(DungeonFloorStatus s) => s switch
    {
        DungeonFloorStatus.Locked => "locked",
        DungeonFloorStatus.Active => "active",
        DungeonFloorStatus.Completed => "completed",
        DungeonFloorStatus.Forfeited => "forfeited",
        _ => "locked",
    };

    private static string ToRunStatusString(DungeonRunStatus s) => s switch
    {
        DungeonRunStatus.NotEntered => "notEntered",
        DungeonRunStatus.InProgress => "inProgress",
        DungeonRunStatus.Completed => "completed",
        DungeonRunStatus.Abandoned => "abandoned",
        _ => "notEntered",
    };
}
