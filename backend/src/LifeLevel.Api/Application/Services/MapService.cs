using LifeLevel.Api.Application.DTOs.Map;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class MapService(AppDbContext db, CharacterService characterService)
{
    public async Task<MapFullResponse> GetFullMapAsync(Guid userId)
    {
        var nodes = await db.MapNodes
            .Include(n => n.Boss)
            .Include(n => n.Chest)
            .Include(n => n.DungeonPortal).ThenInclude(d => d!.Floors)
            .Include(n => n.Crossroads).ThenInclude(c => c!.Paths)
            .ToListAsync();

        // Load per-user states separately and join in memory
        var bossIds = nodes.Where(n => n.Boss != null).Select(n => n.Boss!.Id).ToList();
        var chestIds = nodes.Where(n => n.Chest != null).Select(n => n.Chest!.Id).ToList();
        var dungeonIds = nodes.Where(n => n.DungeonPortal != null).Select(n => n.DungeonPortal!.Id).ToList();
        var crossroadsIds = nodes.Where(n => n.Crossroads != null).Select(n => n.Crossroads!.Id).ToList();

        var bossStates = await db.UserBossStates
            .Where(s => s.UserId == userId && bossIds.Contains(s.BossId))
            .ToListAsync();
        var chestStates = await db.UserChestStates
            .Where(s => s.UserId == userId && chestIds.Contains(s.ChestId))
            .ToListAsync();
        var dungeonStates = await db.UserDungeonStates
            .Where(s => s.UserId == userId && dungeonIds.Contains(s.DungeonPortalId))
            .ToListAsync();
        var crossroadsStates = await db.UserCrossroadsStates
            .Where(s => s.UserId == userId && crossroadsIds.Contains(s.CrossroadsId))
            .ToListAsync();

        var edges = await db.MapEdges.ToListAsync();

        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId);

        if (progress == null)
        {
            progress = await InitializeUserProgressAsync(userId);
        }

        var characterLevel = await db.Characters
            .Where(c => c.UserId == userId)
            .Select(c => c.Level)
            .FirstOrDefaultAsync();

        var unlockedIds = progress.UnlockedNodes.Select(u => u.MapNodeId).ToHashSet();

        return new MapFullResponse
        {
            CharacterLevel = characterLevel,
            Nodes = nodes.Select(n => MapNodeToDto(n, progress, unlockedIds, characterLevel, bossStates, chestStates, dungeonStates, crossroadsStates)).ToList(),
            Edges = edges.Select(e => new MapEdgeDto
            {
                Id = e.Id,
                FromNodeId = e.FromNodeId,
                ToNodeId = e.ToNodeId,
                DistanceKm = e.DistanceKm,
                IsBidirectional = e.IsBidirectional
            }).ToList(),
            UserProgress = new UserMapProgressDto
            {
                CurrentNodeId = progress.CurrentNodeId,
                CurrentEdgeId = progress.CurrentEdgeId,
                DistanceTraveledOnEdge = progress.DistanceTraveledOnEdge,
                DestinationNodeId = progress.DestinationNodeId,
                UnlockedNodeIds = unlockedIds.ToList()
            }
        };
    }

    public async Task SetDestinationAsync(Guid userId, Guid destinationNodeId)
    {
        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? await InitializeUserProgressAsync(userId);

        // Validate the destination node exists
        var destinationNode = await db.MapNodes.FindAsync(destinationNodeId)
            ?? throw new InvalidOperationException("Node not found.");

        // Validate the destination is adjacent to current node (reachable in one edge)
        var isAdjacent = await db.MapEdges.AnyAsync(e =>
            (e.FromNodeId == progress.CurrentNodeId && e.ToNodeId == destinationNodeId) ||
            (e.IsBidirectional && e.ToNodeId == progress.CurrentNodeId && e.FromNodeId == destinationNodeId));

        if (!isAdjacent)
            throw new InvalidOperationException("Destination is not adjacent to your current node.");

        progress.DestinationNodeId = destinationNodeId;
        progress.DistanceTraveledOnEdge = 0;
        progress.UpdatedAt = DateTime.UtcNow;

        // Find and set the current edge
        var edge = await db.MapEdges.FirstOrDefaultAsync(e =>
            (e.FromNodeId == progress.CurrentNodeId && e.ToNodeId == destinationNodeId) ||
            (e.IsBidirectional && e.ToNodeId == progress.CurrentNodeId && e.FromNodeId == destinationNodeId));
        progress.CurrentEdgeId = edge?.Id;

        await db.SaveChangesAsync();
    }

    public async Task DebugTeleportAsync(Guid userId, Guid nodeId)
    {
        var node = await db.MapNodes.FindAsync(nodeId)
            ?? throw new InvalidOperationException("Node not found.");

        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? await InitializeUserProgressAsync(userId);

        progress.CurrentNodeId = nodeId;
        progress.CurrentEdgeId = null;
        progress.DistanceTraveledOnEdge = 0;
        progress.DestinationNodeId = null;
        progress.UpdatedAt = DateTime.UtcNow;

        // Unlock the node if not already unlocked
        var alreadyUnlocked = progress.UnlockedNodes.Any(u => u.MapNodeId == nodeId);
        if (!alreadyUnlocked)
        {
            db.UserNodeUnlocks.Add(new UserNodeUnlock
            {
                UserId = userId,
                MapNodeId = nodeId,
                UserMapProgressId = progress.Id,
                UnlockedAt = DateTime.UtcNow
            });
        }

        await db.SaveChangesAsync();
    }

    public async Task DebugAddDistanceAsync(Guid userId, double km)
    {
        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? await InitializeUserProgressAsync(userId);

        if (progress.CurrentEdgeId == null || progress.DestinationNodeId == null)
            throw new InvalidOperationException("No active destination set. Set a destination first.");

        var edge = await db.MapEdges.FindAsync(progress.CurrentEdgeId)
            ?? throw new InvalidOperationException("Edge not found.");

        progress.DistanceTraveledOnEdge += km;

        MapNode? discoveredNode = null;
        Character? character = null;

        // If we reached or passed the destination
        if (progress.DistanceTraveledOnEdge >= edge.DistanceKm)
        {
            var destinationNodeId = progress.DestinationNodeId.Value;

            progress.CurrentNodeId = destinationNodeId;
            progress.CurrentEdgeId = null;
            progress.DistanceTraveledOnEdge = 0;
            progress.DestinationNodeId = null;

            // Unlock destination node
            var alreadyUnlocked = progress.UnlockedNodes.Any(u => u.MapNodeId == destinationNodeId);
            if (!alreadyUnlocked)
            {
                db.UserNodeUnlocks.Add(new UserNodeUnlock
                {
                    UserId = userId,
                    MapNodeId = destinationNodeId,
                    UserMapProgressId = progress.Id,
                    UnlockedAt = DateTime.UtcNow
                });

                discoveredNode = await db.MapNodes.FindAsync(destinationNodeId);
                character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
                if (discoveredNode != null && character != null && discoveredNode.RewardXp > 0)
                {
                    character.Xp += discoveredNode.RewardXp;
                    character.UpdatedAt = DateTime.UtcNow;
                }
            }
        }

        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        // Record XP history after save
        if (discoveredNode != null && character != null && discoveredNode.RewardXp > 0)
        {
            await characterService.RecordXpAsync(
                character,
                "NodeDiscovery",
                "🗺️",
                $"Discovered {discoveredNode.Name}",
                discoveredNode.RewardXp);
        }
    }

    public async Task<int> DebugAdjustLevelAsync(Guid userId, int delta)
    {
        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        character.Level = Math.Max(1, character.Level + delta);
        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return character.Level;
    }

    public async Task<List<object>> DebugListNodesAsync()
    {
        var nodes = await db.MapNodes
            .Include(n => n.Boss)
            .Include(n => n.Chest)
            .Include(n => n.DungeonPortal)
            .Include(n => n.Crossroads)
            .OrderBy(n => n.Region.ToString()).ThenBy(n => n.Name)
            .ToListAsync();

        return nodes.Select(n => (object)new
        {
            id = n.Id,
            name = n.Name,
            type = n.Type.ToString(),
            region = n.Region.ToString(),
            levelRequirement = n.LevelRequirement,
            isStartNode = n.IsStartNode,
            isHidden = n.IsHidden,
            subEntityId = n.Boss?.Id ?? n.Chest?.Id ?? n.DungeonPortal?.Id ?? n.Crossroads?.Id
        }).ToList();
    }

    public async Task DebugUnlockNodeAsync(Guid userId, Guid nodeId)
    {
        var node = await db.MapNodes.FindAsync(nodeId)
            ?? throw new InvalidOperationException("Node not found.");

        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? await InitializeUserProgressAsync(userId);

        var alreadyUnlocked = progress.UnlockedNodes.Any(u => u.MapNodeId == nodeId);
        if (!alreadyUnlocked)
        {
            db.UserNodeUnlocks.Add(new UserNodeUnlock
            {
                UserId = userId,
                MapNodeId = nodeId,
                UserMapProgressId = progress.Id,
                UnlockedAt = DateTime.UtcNow
            });
            await db.SaveChangesAsync();
        }
    }

    public async Task DebugUnlockAllNodesAsync(Guid userId)
    {
        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? await InitializeUserProgressAsync(userId);

        var allNodeIds = await db.MapNodes.Select(n => n.Id).ToListAsync();
        var unlockedIds = progress.UnlockedNodes.Select(u => u.MapNodeId).ToHashSet();

        foreach (var nodeId in allNodeIds.Where(id => !unlockedIds.Contains(id)))
        {
            db.UserNodeUnlocks.Add(new UserNodeUnlock
            {
                UserId = userId,
                MapNodeId = nodeId,
                UserMapProgressId = progress.Id,
                UnlockedAt = DateTime.UtcNow
            });
        }

        await db.SaveChangesAsync();
    }

    public async Task DebugResetProgressAsync(Guid userId)
    {
        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .Include(p => p.BossStates)
            .Include(p => p.ChestStates)
            .Include(p => p.DungeonStates)
            .Include(p => p.CrossroadsStates)
            .FirstOrDefaultAsync(p => p.UserId == userId);

        if (progress == null) return;

        db.UserNodeUnlocks.RemoveRange(progress.UnlockedNodes);
        db.UserBossStates.RemoveRange(progress.BossStates);
        db.UserChestStates.RemoveRange(progress.ChestStates);
        db.UserDungeonStates.RemoveRange(progress.DungeonStates);
        db.UserCrossroadsStates.RemoveRange(progress.CrossroadsStates);
        db.UserMapProgresses.Remove(progress);

        await db.SaveChangesAsync();
    }

    public async Task<long> DebugSetXpAsync(Guid userId, long xp)
    {
        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        character.Xp = Math.Max(0, xp);
        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return character.Xp;
    }

    private async Task<UserMapProgress> InitializeUserProgressAsync(Guid userId)
    {
        var startNode = await db.MapNodes.FirstAsync(n => n.IsStartNode);

        var progress = new UserMapProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CurrentNodeId = startNode.Id,
            DistanceTraveledOnEdge = 0,
            UpdatedAt = DateTime.UtcNow
        };

        db.UserMapProgresses.Add(progress);

        // Unlock the start node
        db.UserNodeUnlocks.Add(new UserNodeUnlock
        {
            UserId = userId,
            MapNodeId = startNode.Id,
            UserMapProgressId = progress.Id,
            UnlockedAt = DateTime.UtcNow
        });

        await db.SaveChangesAsync();
        return progress;
    }

    private static MapNodeDto MapNodeToDto(
        MapNode node,
        UserMapProgress progress,
        HashSet<Guid> unlockedIds,
        int characterLevel,
        List<UserBossState> bossStates,
        List<UserChestState> chestStates,
        List<UserDungeonState> dungeonStates,
        List<UserCrossroadsState> crossroadsStates)
    {
        var dto = new MapNodeDto
        {
            Id = node.Id,
            Name = node.Name,
            Description = node.Description,
            Icon = node.Icon,
            Type = node.Type.ToString(),
            Region = node.Region.ToString(),
            PositionX = node.PositionX,
            PositionY = node.PositionY,
            LevelRequirement = node.LevelRequirement,
            IsStartNode = node.IsStartNode,
            IsHidden = node.IsHidden,
            RewardXp = node.RewardXp,
            UserState = new NodeUserStateDto
            {
                IsUnlocked = unlockedIds.Contains(node.Id),
                IsLevelMet = characterLevel >= node.LevelRequirement,
                IsCurrentNode = progress.CurrentNodeId == node.Id,
                IsDestination = progress.DestinationNodeId == node.Id
            }
        };

        if (node.Boss != null)
        {
            var userBossState = bossStates.FirstOrDefault(s => s.BossId == node.Boss.Id);
            dto.Boss = new BossDto
            {
                Id = node.Boss.Id,
                Name = node.Boss.Name,
                Icon = node.Boss.Icon,
                MaxHp = node.Boss.MaxHp,
                RewardXp = node.Boss.RewardXp,
                TimerDays = node.Boss.TimerDays,
                IsMini = node.Boss.IsMini,
                HpDealt = userBossState?.HpDealt ?? 0,
                IsDefeated = userBossState?.IsDefeated ?? false,
                IsExpired = userBossState?.IsExpired ?? false,
                StartedAt = userBossState?.StartedAt,
                TimerExpiresAt = userBossState?.StartedAt?.AddDays(node.Boss.TimerDays),
                DefeatedAt = userBossState?.DefeatedAt
            };
        }

        if (node.Chest != null)
        {
            var userChestState = chestStates.FirstOrDefault(s => s.ChestId == node.Chest.Id);
            dto.Chest = new ChestDto
            {
                Id = node.Chest.Id,
                Rarity = node.Chest.Rarity.ToString(),
                RewardXp = node.Chest.RewardXp,
                IsCollected = userChestState?.IsCollected ?? false
            };
        }

        if (node.DungeonPortal != null)
        {
            var userDungeonState = dungeonStates.FirstOrDefault(s => s.DungeonPortalId == node.DungeonPortal.Id);
            dto.DungeonPortal = new DungeonPortalDto
            {
                Id = node.DungeonPortal.Id,
                Name = node.DungeonPortal.Name,
                TotalFloors = node.DungeonPortal.TotalFloors,
                CurrentFloor = userDungeonState?.CurrentFloor ?? 0,
                IsDiscovered = userDungeonState?.IsDiscovered ?? false,
                Floors = node.DungeonPortal.Floors.OrderBy(f => f.FloorNumber).Select(f => new DungeonFloorDto
                {
                    FloorNumber = f.FloorNumber,
                    RequiredActivity = f.RequiredActivity.ToString(),
                    RequiredMinutes = f.RequiredMinutes,
                    RewardXp = f.RewardXp
                }).ToList()
            };
        }

        if (node.Crossroads != null)
        {
            var userCrossroadsState = crossroadsStates.FirstOrDefault(s => s.CrossroadsId == node.Crossroads.Id);
            dto.Crossroads = new CrossroadsDto
            {
                Id = node.Crossroads.Id,
                ChosenPathId = userCrossroadsState?.ChosenPathId,
                Paths = node.Crossroads.Paths.Select(p => new CrossroadsPathDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    DistanceKm = p.DistanceKm,
                    Difficulty = p.Difficulty.ToString(),
                    EstimatedDays = p.EstimatedDays,
                    RewardXp = p.RewardXp,
                    AdditionalRequirement = p.AdditionalRequirement,
                    LeadsToNodeId = p.LeadsToNodeId
                }).ToList()
            };
        }

        return dto;
    }
}
