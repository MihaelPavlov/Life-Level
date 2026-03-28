using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class DungeonService(AppDbContext db, CharacterService characterService)
{
    /// <summary>
    /// Discover dungeon (enter). Zone check enforced. Creates UserDungeonState if not present.
    /// </summary>
    public async Task<UserDungeonState> DiscoverAsync(Guid userId, Guid dungeonId)
    {
        var dungeon = await db.DungeonPortals.FindAsync(dungeonId)
            ?? throw new InvalidOperationException("Dungeon not found.");

        var progress = await db.UserMapProgresses
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (progress.CurrentNodeId != dungeon.NodeId)
            throw new InvalidOperationException("You must be at the dungeon node to enter.");

        var existing = await db.UserDungeonStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.DungeonPortalId == dungeonId);

        if (existing != null) return existing;

        var state = new UserDungeonState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DungeonPortalId = dungeonId,
            UserMapProgressId = progress.Id,
            IsDiscovered = true,
            CurrentFloor = 0,
            DiscoveredAt = DateTime.UtcNow
        };

        db.UserDungeonStates.Add(state);
        await db.SaveChangesAsync();
        return state;
    }

    /// <summary>
    /// Complete the next dungeon floor. Zone check enforced.
    /// Must complete floors in order. Awards floor XP.
    /// </summary>
    public async Task<CompleteFloorResult> CompleteFloorAsync(Guid userId, Guid dungeonId, int floorNumber)
    {
        var dungeon = await db.DungeonPortals
            .Include(d => d.Floors)
            .FirstOrDefaultAsync(d => d.Id == dungeonId)
            ?? throw new InvalidOperationException("Dungeon not found.");

        var progress = await db.UserMapProgresses
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (progress.CurrentNodeId != dungeon.NodeId)
            throw new InvalidOperationException("You must be at the dungeon node to complete floors.");

        var state = await db.UserDungeonStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.DungeonPortalId == dungeonId)
            ?? throw new InvalidOperationException("You must enter the dungeon first.");

        if (!state.IsDiscovered)
            throw new InvalidOperationException("You must enter the dungeon first.");

        if (floorNumber != state.CurrentFloor + 1)
            throw new InvalidOperationException($"Must complete floor {state.CurrentFloor + 1} next.");

        if (floorNumber > dungeon.TotalFloors)
            throw new InvalidOperationException("All floors already completed.");

        var floor = dungeon.Floors.FirstOrDefault(f => f.FloorNumber == floorNumber)
            ?? throw new InvalidOperationException($"Floor {floorNumber} not found.");

        state.CurrentFloor = floorNumber;

        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
        if (character != null)
        {
            character.Xp += floor.RewardXp;
            character.UpdatedAt = DateTime.UtcNow;
        }

        await db.SaveChangesAsync();

        bool leveledUp = false;
        int newLevel = 0;
        if (character != null)
            (leveledUp, newLevel) = await characterService.RecordXpAsync(
                character,
                "DungeonFloor",
                "🌀",
                $"{dungeon.Name} · Floor {floorNumber} completed",
                floor.RewardXp);

        return new CompleteFloorResult
        {
            CompletedFloor = floorNumber,
            RewardXp = floor.RewardXp,
            CurrentFloor = state.CurrentFloor,
            TotalFloors = dungeon.TotalFloors,
            IsFullyCleared = state.CurrentFloor >= dungeon.TotalFloors,
            LeveledUp = leveledUp,
            NewLevel = newLevel
        };
    }

    // ── Debug ──────────────────────────────────────────────────────────────────

    /// <summary>Debug: set current floor directly. No zone check.</summary>
    public async Task DebugSetFloorAsync(Guid userId, Guid dungeonId, int floor)
    {
        var dungeon = await db.DungeonPortals.FindAsync(dungeonId)
            ?? throw new InvalidOperationException("Dungeon not found.");

        var state = await EnsureStateAsync(userId, dungeonId);
        state.CurrentFloor = Math.Clamp(floor, 0, dungeon.TotalFloors);
        state.IsDiscovered = state.CurrentFloor > 0 || state.IsDiscovered;
        await db.SaveChangesAsync();
    }

    /// <summary>Debug: reset dungeon state.</summary>
    public async Task DebugResetAsync(Guid userId, Guid dungeonId)
    {
        var state = await db.UserDungeonStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.DungeonPortalId == dungeonId);

        if (state != null)
        {
            db.UserDungeonStates.Remove(state);
            await db.SaveChangesAsync();
        }
    }

    private async Task<UserDungeonState> EnsureStateAsync(Guid userId, Guid dungeonId)
    {
        var existing = await db.UserDungeonStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.DungeonPortalId == dungeonId);

        if (existing != null) return existing;

        var progress = await db.UserMapProgresses
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        var state = new UserDungeonState
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DungeonPortalId = dungeonId,
            UserMapProgressId = progress.Id,
            IsDiscovered = false,
            CurrentFloor = 0
        };

        db.UserDungeonStates.Add(state);
        return state;
    }
}

public class CompleteFloorResult
{
    public int CompletedFloor { get; set; }
    public int RewardXp { get; set; }
    public int CurrentFloor { get; set; }
    public int TotalFloors { get; set; }
    public bool IsFullyCleared { get; set; }
    public bool LeveledUp { get; set; }
    public int NewLevel { get; set; }
}
