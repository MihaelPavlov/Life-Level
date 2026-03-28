using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class CrossroadsService(AppDbContext db, CharacterService characterService)
{
    /// <summary>
    /// Choose a crossroads path. Zone check enforced. One-time choice (cannot change).
    /// Also sets the chosen path's destination node as the player's travel destination.
    /// </summary>
    public async Task<ChoosePathResult> ChoosePathAsync(Guid userId, Guid crossroadsId, Guid pathId)
    {
        var crossroads = await db.Crossroads
            .Include(c => c.Paths)
            .FirstOrDefaultAsync(c => c.Id == crossroadsId)
            ?? throw new InvalidOperationException("Crossroads not found.");

        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (progress.CurrentNodeId != crossroads.NodeId)
            throw new InvalidOperationException("You must be at the crossroads to choose a path.");

        var existing = await db.UserCrossroadsStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.CrossroadsId == crossroadsId);

        if (existing?.ChosenPathId != null)
            throw new InvalidOperationException("Path already chosen. Cannot change selection.");

        var path = crossroads.Paths.FirstOrDefault(p => p.Id == pathId)
            ?? throw new InvalidOperationException("Path not found on this crossroads.");

        if (existing == null)
        {
            existing = new UserCrossroadsState
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                CrossroadsId = crossroadsId,
                UserMapProgressId = progress.Id
            };
            db.UserCrossroadsStates.Add(existing);
        }

        existing.ChosenPathId = pathId;
        existing.ChosenAt = DateTime.UtcNow;

        // Set the path destination as the player's travel target
        if (path.LeadsToNodeId.HasValue)
        {
            var edge = await db.MapEdges.FirstOrDefaultAsync(e =>
                (e.FromNodeId == crossroads.NodeId && e.ToNodeId == path.LeadsToNodeId) ||
                (e.IsBidirectional && e.ToNodeId == crossroads.NodeId && e.FromNodeId == path.LeadsToNodeId));

            progress.DestinationNodeId = path.LeadsToNodeId;
            progress.CurrentEdgeId = edge?.Id;
            progress.DistanceTraveledOnEdge = 0;
            progress.UpdatedAt = DateTime.UtcNow;
        }

        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
        if (character != null && path.RewardXp > 0)
        {
            character.Xp += path.RewardXp;
            character.UpdatedAt = DateTime.UtcNow;
        }

        await db.SaveChangesAsync();

        bool leveledUp = false;
        int newLevel = 0;
        if (character != null && path.RewardXp > 0)
            (leveledUp, newLevel) = await characterService.RecordXpAsync(
                character,
                "CrossroadsPath",
                "🔀",
                $"Chose path: {path.Name}",
                path.RewardXp);

        return new ChoosePathResult
        {
            PathId = pathId,
            PathName = path.Name,
            LeadsToNodeId = path.LeadsToNodeId,
            RewardXp = path.RewardXp,
            ChosenAt = existing.ChosenAt!.Value,
            LeveledUp = leveledUp,
            NewLevel = newLevel
        };
    }

    // ── Debug ──────────────────────────────────────────────────────────────────

    /// <summary>Debug: reset crossroads state so a path can be re-chosen.</summary>
    public async Task DebugResetAsync(Guid userId, Guid crossroadsId)
    {
        var state = await db.UserCrossroadsStates
            .FirstOrDefaultAsync(s => s.UserId == userId && s.CrossroadsId == crossroadsId);

        if (state != null)
        {
            db.UserCrossroadsStates.Remove(state);
            await db.SaveChangesAsync();
        }
    }
}

public class ChoosePathResult
{
    public Guid PathId { get; set; }
    public string PathName { get; set; } = string.Empty;
    public Guid? LeadsToNodeId { get; set; }
    public int RewardXp { get; set; }
    public DateTime ChosenAt { get; set; }
    public bool LeveledUp { get; set; }
    public int NewLevel { get; set; }
}
