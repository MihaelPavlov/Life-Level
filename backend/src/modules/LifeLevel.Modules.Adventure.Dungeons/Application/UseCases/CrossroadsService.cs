using LifeLevel.Modules.Adventure.Dungeons.Application.DTOs;
using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Adventure.Dungeons.Application.UseCases;

public class CrossroadsService(DbContext db, ICharacterXpPort characterXp)
{
    public async Task<ChoosePathResult> ChoosePathAsync(Guid userId, Guid crossroadsId, Guid pathId)
    {
        var crossroads = await db.Set<Crossroads>()
            .Include(c => c.Paths)
            .FirstOrDefaultAsync(c => c.Id == crossroadsId)
            ?? throw new InvalidOperationException("Crossroads not found.");

        var progress = await db.Set<UserMapProgress>()
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? throw new InvalidOperationException("Map progress not found.");

        if (progress.CurrentNodeId != crossroads.NodeId)
            throw new InvalidOperationException("You must be at the crossroads to choose a path.");

        var existing = await db.Set<UserCrossroadsState>()
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
            db.Set<UserCrossroadsState>().Add(existing);
        }

        existing.ChosenPathId = pathId;
        existing.ChosenAt = DateTime.UtcNow;

        if (path.LeadsToNodeId.HasValue)
        {
            var edge = await db.Set<MapEdge>().FirstOrDefaultAsync(e =>
                (e.FromNodeId == crossroads.NodeId && e.ToNodeId == path.LeadsToNodeId) ||
                (e.IsBidirectional && e.ToNodeId == crossroads.NodeId && e.FromNodeId == path.LeadsToNodeId));

            progress.DestinationNodeId = path.LeadsToNodeId;
            progress.CurrentEdgeId = edge?.Id;
            progress.DistanceTraveledOnEdge = 0;
            progress.UpdatedAt = DateTime.UtcNow;
        }

        await db.SaveChangesAsync();

        if (path.RewardXp > 0)
        {
            await characterXp.AwardXpAsync(
                userId,
                "CrossroadsPath",
                "🔀",
                $"Chose path: {path.Name}",
                path.RewardXp);
        }

        return new ChoosePathResult
        {
            PathId = pathId,
            PathName = path.Name,
            LeadsToNodeId = path.LeadsToNodeId,
            RewardXp = path.RewardXp,
            ChosenAt = existing.ChosenAt!.Value
        };
    }

    public async Task DebugResetAsync(Guid userId, Guid crossroadsId)
    {
        var state = await db.Set<UserCrossroadsState>()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.CrossroadsId == crossroadsId);

        if (state != null)
        {
            db.Set<UserCrossroadsState>().Remove(state);
            await db.SaveChangesAsync();
        }
    }
}
