using LifeLevel.Modules.Adventure.Dungeons.Application.DTOs;
using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Adventure.Dungeons.Application.UseCases;

public class DungeonService(DbContext db, ICharacterXpPort characterXp)
{
    public async Task<UserDungeonState> DiscoverAsync(Guid userId, Guid dungeonId)
    {
        var dungeon = await db.Set<DungeonPortal>().FindAsync(dungeonId)
            ?? throw new InvalidOperationException("Dungeon not found.");

        var progress = await db.Set<UserMapProgress>()
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (progress.CurrentNodeId != dungeon.NodeId)
            throw new InvalidOperationException("You must be at the dungeon node to enter.");

        var existing = await db.Set<UserDungeonState>()
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

        db.Set<UserDungeonState>().Add(state);
        await db.SaveChangesAsync();
        return state;
    }

    public async Task<CompleteFloorResult> CompleteFloorAsync(Guid userId, Guid dungeonId, int floorNumber)
    {
        var dungeon = await db.Set<DungeonPortal>()
            .Include(d => d.Floors)
            .FirstOrDefaultAsync(d => d.Id == dungeonId)
            ?? throw new InvalidOperationException("Dungeon not found.");

        var progress = await db.Set<UserMapProgress>()
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (progress.CurrentNodeId != dungeon.NodeId)
            throw new InvalidOperationException("You must be at the dungeon node to complete floors.");

        var state = await db.Set<UserDungeonState>()
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

        await db.SaveChangesAsync();

        await characterXp.AwardXpAsync(
            userId,
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
            IsFullyCleared = state.CurrentFloor >= dungeon.TotalFloors
        };
    }

    public async Task DebugSetFloorAsync(Guid userId, Guid dungeonId, int floor)
    {
        var dungeon = await db.Set<DungeonPortal>().FindAsync(dungeonId)
            ?? throw new InvalidOperationException("Dungeon not found.");

        var state = await EnsureStateAsync(userId, dungeonId);
        state.CurrentFloor = Math.Clamp(floor, 0, dungeon.TotalFloors);
        state.IsDiscovered = state.CurrentFloor > 0 || state.IsDiscovered;
        await db.SaveChangesAsync();
    }

    public async Task DebugResetAsync(Guid userId, Guid dungeonId)
    {
        var state = await db.Set<UserDungeonState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.DungeonPortalId == dungeonId);

        if (state != null)
        {
            db.Set<UserDungeonState>().Remove(state);
            await db.SaveChangesAsync();
        }
    }

    private async Task<UserDungeonState> EnsureStateAsync(Guid userId, Guid dungeonId)
    {
        var existing = await db.Set<UserDungeonState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.DungeonPortalId == dungeonId);

        if (existing != null) return existing;

        var progress = await db.Set<UserMapProgress>()
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

        db.Set<UserDungeonState>().Add(state);
        return state;
    }
}
