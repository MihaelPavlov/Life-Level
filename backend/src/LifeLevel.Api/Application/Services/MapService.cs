using LifeLevel.Api.Application.DTOs.Map;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using LifeLevel.Modules.Adventure.Dungeons.Domain.Enums;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Enums;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;

// Type alias to avoid clash with namespace segment
using CrossroadsEntity = LifeLevel.Modules.Adventure.Dungeons.Domain.Entities.Crossroads;

namespace LifeLevel.Api.Application.Services;

public class MapService(
    AppDbContext db,
    ICharacterXpPort characterXp,
    IWorldZoneDistancePort worldZoneDistance,
    ILogger<MapService>? logger = null) : IMapDistancePort
{
    public async Task AddDistanceAsync(Guid userId, double km, CancellationToken ct = default)
    {
        if (km <= 0) return;
        await DebugAddDistanceAsync(userId, km);
    }

    public async Task<MapFullResponse> GetFullMapAsync(Guid userId, Guid? worldZoneId = null)
    {
        var nodesQuery = db.MapNodes.AsQueryable();
        if (worldZoneId.HasValue)
            nodesQuery = nodesQuery.Where(n => n.WorldZoneId == worldZoneId.Value);
        var nodes = await nodesQuery.ToListAsync();

        var nodeIds = nodes.Select(n => n.Id).ToHashSet();

        // Load adventure sub-entities separately (MapNode no longer has nav props to these)
        var bosses = await db.Bosses.Where(b => nodeIds.Contains(b.NodeId)).ToListAsync();
        var chests = await db.Chests.Where(c => nodeIds.Contains(c.NodeId)).ToListAsync();
        var dungeons = await db.DungeonPortals
            .Include(d => d.Floors)
            .Where(d => nodeIds.Contains(d.NodeId))
            .ToListAsync();
        var crossroadsList = await db.Crossroads
            .Include(c => c.Paths)
            .Where(c => nodeIds.Contains(c.NodeId))
            .ToListAsync();

        var bossIds = bosses.Select(b => b.Id).ToList();
        var chestIds = chests.Select(c => c.Id).ToList();
        var dungeonIds = dungeons.Select(d => d.Id).ToList();
        var crossroadsIds = crossroadsList.Select(c => c.Id).ToList();

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

        var edges = await db.MapEdges
            .Where(e => nodeIds.Contains(e.FromNodeId) && nodeIds.Contains(e.ToNodeId))
            .ToListAsync();

        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId);

        if (progress == null)
        {
            if (nodes.Count == 0)
            {
                return new MapFullResponse
                {
                    CharacterLevel = 0,
                    Nodes = [],
                    Edges = [],
                    UserProgress = new UserMapProgressDto
                    {
                        CurrentNodeId = Guid.Empty,
                        UnlockedNodeIds = []
                    }
                };
            }
            progress = await InitializeUserProgressAsync(userId, worldZoneId);
        }

        // If the user's current node is not in this zone (they've entered a new zone),
        // auto-place them at the zone's start node so adjacency checks work correctly.
        if (worldZoneId.HasValue && nodes.Count > 0 && !nodeIds.Contains(progress.CurrentNodeId))
        {
            var startNode = nodes.FirstOrDefault(n => n.IsStartNode)
                ?? nodes.First();

            progress.CurrentNodeId = startNode.Id;
            progress.CurrentEdgeId = null;
            progress.DistanceTraveledOnEdge = 0;
            progress.DestinationNodeId = null;
            progress.UpdatedAt = DateTime.UtcNow;

            var alreadyUnlocked = progress.UnlockedNodes.Any(u => u.MapNodeId == startNode.Id);
            if (!alreadyUnlocked)
            {
                var unlock = new UserNodeUnlock
                {
                    UserId = userId,
                    MapNodeId = startNode.Id,
                    UserMapProgressId = progress.Id,
                    UnlockedAt = DateTime.UtcNow
                };
                db.UserNodeUnlocks.Add(unlock);
                progress.UnlockedNodes.Add(unlock);
            }

            await db.SaveChangesAsync();
        }

        var characterLevel = await db.Characters
            .Where(c => c.UserId == userId)
            .Select(c => c.Level)
            .FirstOrDefaultAsync();

        var unlockedIds = progress.UnlockedNodes.Select(u => u.MapNodeId).ToHashSet();

        // Build lookup dictionaries by NodeId
        var bossByNodeId = bosses.ToDictionary(b => b.NodeId);
        var chestByNodeId = chests.ToDictionary(c => c.NodeId);
        var dungeonByNodeId = dungeons.ToDictionary(d => d.NodeId);
        var crossroadsByNodeId = crossroadsList.ToDictionary(c => c.NodeId);

        return new MapFullResponse
        {
            CharacterLevel = characterLevel,
            Nodes = nodes.Select(n => MapNodeToDto(
                n, progress, unlockedIds, characterLevel,
                bossByNodeId, chestByNodeId, dungeonByNodeId, crossroadsByNodeId,
                bossStates, chestStates, dungeonStates, crossroadsStates)).ToList(),
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
                UnlockedNodeIds = unlockedIds.ToList(),
                PendingDistanceKm = progress.PendingDistanceKm
            }
        };
    }

    public async Task SetDestinationAsync(Guid userId, Guid destinationNodeId)
    {
        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId)
            ?? await InitializeUserProgressAsync(userId);

        var destinationNode = await db.MapNodes.FindAsync(destinationNodeId)
            ?? throw new InvalidOperationException("Node not found.");

        var isAdjacent = await db.MapEdges.AnyAsync(e =>
            (e.FromNodeId == progress.CurrentNodeId && e.ToNodeId == destinationNodeId) ||
            (e.IsBidirectional && e.ToNodeId == progress.CurrentNodeId && e.FromNodeId == destinationNodeId));

        if (!isAdjacent)
            throw new InvalidOperationException("Destination is not adjacent to your current node.");

        var pendingKm = progress.PendingDistanceKm;
        progress.DestinationNodeId = destinationNodeId;
        progress.DistanceTraveledOnEdge = 0;
        progress.PendingDistanceKm = 0;
        progress.UpdatedAt = DateTime.UtcNow;

        var edge = await db.MapEdges.FirstOrDefaultAsync(e =>
            (e.FromNodeId == progress.CurrentNodeId && e.ToNodeId == destinationNodeId) ||
            (e.IsBidirectional && e.ToNodeId == progress.CurrentNodeId && e.FromNodeId == destinationNodeId));
        progress.CurrentEdgeId = edge?.Id;

        await db.SaveChangesAsync();

        // Apply any banked distance to the new edge (may complete the edge instantly).
        if (pendingKm > 0)
            await DebugAddDistanceAsync(userId, pendingKm);
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
        var log = logger ?? NullLogger<MapService>.Instance;

        // Cascade every incoming km to the world-zone travel as well. This is
        // the single choke-point for local-map distance (both real activities
        // and the debug add-distance / teleport paths flow through here), so
        // bumping world here unifies the two systems without double-counting.
        // IWorldZoneDistancePort.AddDistanceAsync silently no-ops when no world
        // destination is set, so this is safe for all scenarios.
        if (km > 0)
        {
            log.LogInformation("MapService.DebugAddDistance cascade-to-world user={UserId} km={Km}", userId, km);
            await worldZoneDistance.AddDistanceAsync(userId, km);
        }

        var progress = await db.UserMapProgresses
            .Include(p => p.UnlockedNodes)
            .FirstOrDefaultAsync(p => p.UserId == userId);

        if (progress == null)
        {
            // New users have no local-map progress — the legacy per-zone MapNode
            // graph is initialised lazily when the user opens the local map.
            // World-zone distance was already cascaded above, which is the
            // canonical progression surface now, so silently skip.
            return;
        }

        if (progress.DestinationNodeId == null)
        {
            // No destination set — bank the distance as a reserve that will be
            // applied automatically when the user picks their next destination.
            progress.PendingDistanceKm += km;
            progress.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
            return;
        }

        var edge = await db.MapEdges.FindAsync(progress.CurrentEdgeId)
            ?? throw new InvalidOperationException("Edge not found.");

        progress.DistanceTraveledOnEdge += km;

        MapNode? discoveredNode = null;

        if (progress.DistanceTraveledOnEdge >= edge.DistanceKm)
        {
            var destinationNodeId = progress.DestinationNodeId.Value;
            var excessKm = progress.DistanceTraveledOnEdge - edge.DistanceKm;

            progress.CurrentNodeId = destinationNodeId;
            progress.CurrentEdgeId = null;
            progress.DistanceTraveledOnEdge = 0;
            progress.DestinationNodeId = null;
            progress.PendingDistanceKm = excessKm > 0 ? excessKm : 0;

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
            }
        }

        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        if (discoveredNode != null && discoveredNode.RewardXp > 0)
        {
            await characterXp.AwardXpAsync(
                userId,
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

        var newLevel = Math.Max(1, character.Level + delta);
        var levelsGained = newLevel - character.Level;

        character.Level = newLevel;
        if (levelsGained > 0)
            character.AvailableStatPoints += levelsGained;

        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return character.Level;
    }

    public async Task<List<object>> DebugListNodesAsync()
    {
        var nodes = await db.MapNodes
            .OrderBy(n => n.Region.ToString()).ThenBy(n => n.Name)
            .ToListAsync();

        var nodeIds = nodes.Select(n => n.Id).ToHashSet();
        var bosses = await db.Bosses.Where(b => nodeIds.Contains(b.NodeId)).ToListAsync();
        var chests = await db.Chests.Where(c => nodeIds.Contains(c.NodeId)).ToListAsync();
        var dungeons = await db.DungeonPortals.Where(d => nodeIds.Contains(d.NodeId)).ToListAsync();
        var crossroadsList = await db.Crossroads.Where(c => nodeIds.Contains(c.NodeId)).ToListAsync();

        return nodes.Select(n => (object)new
        {
            id = n.Id,
            name = n.Name,
            type = n.Type.ToString(),
            region = n.Region.ToString(),
            levelRequirement = n.LevelRequirement,
            isStartNode = n.IsStartNode,
            isHidden = n.IsHidden,
            subEntityId = bosses.FirstOrDefault(b => b.NodeId == n.Id)?.Id
                       ?? chests.FirstOrDefault(c => c.NodeId == n.Id)?.Id
                       ?? dungeons.FirstOrDefault(d => d.NodeId == n.Id)?.Id
                       ?? crossroadsList.FirstOrDefault(c => c.NodeId == n.Id)?.Id
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
            .FirstOrDefaultAsync(p => p.UserId == userId);

        if (progress == null) return;

        // Load adventure states separately (UserMapProgress no longer has these nav props)
        var bossStates = await db.UserBossStates.Where(s => s.UserMapProgressId == progress.Id).ToListAsync();
        var chestStates = await db.UserChestStates.Where(s => s.UserMapProgressId == progress.Id).ToListAsync();
        var dungeonStates = await db.UserDungeonStates.Where(s => s.UserMapProgressId == progress.Id).ToListAsync();
        var crossroadsStates = await db.UserCrossroadsStates.Where(s => s.UserMapProgressId == progress.Id).ToListAsync();

        db.UserNodeUnlocks.RemoveRange(progress.UnlockedNodes);
        db.UserBossStates.RemoveRange(bossStates);
        db.UserChestStates.RemoveRange(chestStates);
        db.UserDungeonStates.RemoveRange(dungeonStates);
        db.UserCrossroadsStates.RemoveRange(crossroadsStates);
        db.UserMapProgresses.Remove(progress);

        await db.SaveChangesAsync();
    }

    public async Task<long> DebugSetXpAsync(Guid userId, long xp)
    {
        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        character.Xp = Math.Max(0, xp);
        character.Level = 1;
        character.AvailableStatPoints = 0;

        while (character.Xp >= XpAtLevelStart(character.Level + 1))
        {
            character.Level++;
            character.AvailableStatPoints++;
        }

        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        return character.Xp;
    }

    private static long XpAtLevelStart(int level) =>
        (long)level * (level - 1) / 2 * 300;

    private async Task<UserMapProgress> InitializeUserProgressAsync(Guid userId, Guid? worldZoneId = null)
    {
        MapNode? startNode = null;
        if (worldZoneId.HasValue)
            startNode = await db.MapNodes.FirstOrDefaultAsync(n => n.IsStartNode && n.WorldZoneId == worldZoneId.Value);

        if (startNode == null)
            throw new InvalidOperationException(
                $"No start node found for zone {worldZoneId}. Ensure the zone has been seeded with map nodes.");

        var progress = new UserMapProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CurrentNodeId = startNode.Id,
            DistanceTraveledOnEdge = 0,
            UpdatedAt = DateTime.UtcNow
        };

        db.UserMapProgresses.Add(progress);

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
        Dictionary<Guid, Boss> bossByNodeId,
        Dictionary<Guid, Chest> chestByNodeId,
        Dictionary<Guid, DungeonPortal> dungeonByNodeId,
        Dictionary<Guid, CrossroadsEntity> crossroadsByNodeId,
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

        if (bossByNodeId.TryGetValue(node.Id, out var boss))
        {
            var userBossState = bossStates.FirstOrDefault(s => s.BossId == boss.Id);
            dto.Boss = new BossDto
            {
                Id = boss.Id,
                Name = boss.Name,
                Icon = boss.Icon,
                MaxHp = boss.MaxHp,
                RewardXp = boss.RewardXp,
                TimerDays = boss.TimerDays,
                IsMini = boss.IsMini,
                HpDealt = userBossState?.HpDealt ?? 0,
                IsDefeated = userBossState?.IsDefeated ?? false,
                IsExpired = userBossState?.IsExpired ?? false,
                StartedAt = userBossState?.StartedAt,
                TimerExpiresAt = userBossState?.StartedAt?.AddDays(boss.TimerDays),
                DefeatedAt = userBossState?.DefeatedAt
            };
        }

        if (chestByNodeId.TryGetValue(node.Id, out var chest))
        {
            var userChestState = chestStates.FirstOrDefault(s => s.ChestId == chest.Id);
            dto.Chest = new ChestDto
            {
                Id = chest.Id,
                Rarity = chest.Rarity.ToString(),
                RewardXp = chest.RewardXp,
                IsCollected = userChestState?.IsCollected ?? false
            };
        }

        if (dungeonByNodeId.TryGetValue(node.Id, out var dungeon))
        {
            var userDungeonState = dungeonStates.FirstOrDefault(s => s.DungeonPortalId == dungeon.Id);
            dto.DungeonPortal = new DungeonPortalDto
            {
                Id = dungeon.Id,
                Name = dungeon.Name,
                TotalFloors = dungeon.TotalFloors,
                CurrentFloor = userDungeonState?.CurrentFloor ?? 0,
                IsDiscovered = userDungeonState?.IsDiscovered ?? false,
                Floors = dungeon.Floors.OrderBy(f => f.FloorNumber).Select(f => new DungeonFloorDto
                {
                    FloorNumber = f.FloorNumber,
                    RequiredActivity = f.RequiredActivity.ToString(),
                    RequiredMinutes = f.RequiredMinutes,
                    RewardXp = f.RewardXp
                }).ToList()
            };
        }

        if (crossroadsByNodeId.TryGetValue(node.Id, out var crossroads))
        {
            var userCrossroadsState = crossroadsStates.FirstOrDefault(s => s.CrossroadsId == crossroads.Id);
            dto.Crossroads = new CrossroadsDto
            {
                Id = crossroads.Id,
                ChosenPathId = userCrossroadsState?.ChosenPathId,
                Paths = crossroads.Paths.Select(p => new CrossroadsPathDto
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
