using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Domain.Enums;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/admin/map")]
[Authorize(Roles = "Admin")]
public class AdminMapController(AppDbContext db) : ControllerBase
{
    // -------------------------------------------------------------------------
    // BULK / HTML ADMIN PANEL
    // -------------------------------------------------------------------------

    [HttpGet("health")]
    [AllowAnonymous]
    public IActionResult Health() => Ok(new { status = "ok", timestamp = DateTime.UtcNow });

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var nodes = await db.MapNodes
            .Select(n => new
            {
                id          = n.Id.ToString(),
                name        = n.Name,
                description = n.Description,
                icon        = n.Icon,
                type        = n.Type.ToString(),
                region      = n.Region.ToString(),
                x           = (double)n.PositionX,
                y           = (double)n.PositionY,
                levelReq    = n.LevelRequirement,
                rewardXp    = n.RewardXp,
                isStart     = n.IsStartNode,
                isHidden    = n.IsHidden,
                worldZoneId = n.WorldZoneId.HasValue ? n.WorldZoneId.Value.ToString() : (string?)null,
            })
            .ToListAsync();

        var edges = await db.MapEdges
            .Select(e => new
            {
                id            = e.Id.ToString(),
                fromNodeId    = e.FromNodeId.ToString(),
                toNodeId      = e.ToNodeId.ToString(),
                distanceKm    = e.DistanceKm,
                bidirectional = e.IsBidirectional,
            })
            .ToListAsync();

        var bosses = await db.Bosses
            .Select(b => new
            {
                id        = b.Id.ToString(),
                nodeId    = b.NodeId.ToString(),
                name      = b.Name,
                icon      = b.Icon,
                maxHp     = b.MaxHp,
                rewardXp  = b.RewardXp,
                timerDays = b.TimerDays,
                isMini    = b.IsMini,
            })
            .ToListAsync();

        var dungeons = await db.DungeonPortals
            .Include(d => d.Floors)
            .Select(d => new
            {
                id          = d.Id.ToString(),
                nodeId      = d.NodeId.ToString(),
                name        = d.Name,
                totalFloors = d.TotalFloors,
                floors      = d.Floors.OrderBy(f => f.FloorNumber).Select(f => new
                {
                    id               = f.Id.ToString(),
                    floor            = f.FloorNumber,
                    requiredActivity = f.RequiredActivity.ToString(),
                    requiredMinutes  = f.RequiredMinutes,
                    rewardXp         = f.RewardXp,
                }).ToList(),
            })
            .ToListAsync();

        var chests = await db.Chests
            .Select(c => new
            {
                id       = c.Id.ToString(),
                nodeId   = c.NodeId.ToString(),
                rarity   = c.Rarity.ToString(),
                rewardXp = c.RewardXp,
            })
            .ToListAsync();

        var crossroads = await db.Crossroads
            .Include(c => c.Paths)
            .Select(c => new
            {
                id     = c.Id.ToString(),
                nodeId = c.NodeId.ToString(),
                paths  = c.Paths.Select(p => new
                {
                    id                    = p.Id.ToString(),
                    name                  = p.Name,
                    distanceKm            = p.DistanceKm,
                    difficulty            = p.Difficulty.ToString(),
                    estimatedDays         = p.EstimatedDays,
                    rewardXp              = p.RewardXp,
                    additionalRequirement = p.AdditionalRequirement,
                    leadsToNodeId         = p.LeadsToNodeId.HasValue ? p.LeadsToNodeId.ToString() : null,
                }).ToList(),
            })
            .ToListAsync();

        var worldZones = await db.WorldZones
            .Select(z => new
            {
                id              = z.Id.ToString(),
                name            = z.Name,
                description     = z.Description,
                icon            = z.Icon,
                region          = z.Region,
                tier            = z.Tier,
                x               = (double)z.PositionX,
                y               = (double)z.PositionY,
                levelReq        = z.LevelRequirement,
                totalXp         = z.TotalXp,
                totalDistanceKm = z.TotalDistanceKm,
                isCrossroads    = z.IsCrossroads,
                isStart         = z.IsStartZone,
                isHidden        = z.IsHidden,
            })
            .ToListAsync();

        var worldEdges = await db.WorldZoneEdges
            .Select(e => new
            {
                id            = e.Id.ToString(),
                fromZoneId    = e.FromZoneId.ToString(),
                toZoneId      = e.ToZoneId.ToString(),
                distanceKm    = e.DistanceKm,
                bidirectional = e.IsBidirectional,
            })
            .ToListAsync();

        return Ok(new { nodes, edges, bosses, dungeons, chests, crossroads, worldZones, worldEdges });
    }

    [HttpPost]
    public async Task<IActionResult> SyncAll([FromBody] MapSyncPayload payload)
    {
        // Strategy: preserve node GUIDs so existing users keep their map position/unlocks.
        // - Nodes with a real GUID in the payload → upsert (keep GUID, update fields)
        // - Nodes with a temp ID → insert as new
        // - Nodes no longer in the payload → delete + clean up user state pointing to them
        // - Sub-entities (bosses, chests, dungeons, crossroads) → always replace; their
        //   user states (boss HP, chest collected, etc.) are wiped since content changed.

        // ── Resolve incoming node GUIDs ────────────────────────────────────────────
        var nodeIdMap = new Dictionary<string, Guid>(); // temp ID → assigned GUID
        var incomingNodeGuids = new HashSet<Guid>();

        foreach (var n in payload.Nodes ?? [])
        {
            if (Guid.TryParse(n.Id, out var guid))
                incomingNodeGuids.Add(guid);
            else
            {
                guid = Guid.NewGuid();
                if (n.Id != null) nodeIdMap[n.Id] = guid;
                incomingNodeGuids.Add(guid);
            }
        }

        // ── Delete nodes removed from the map + dependent user state ──────────────
        var removedNodeIds = await db.MapNodes
            .Where(n => !incomingNodeGuids.Contains(n.Id))
            .Select(n => n.Id)
            .ToListAsync();

        if (removedNodeIds.Count > 0)
        {
            // Null out CurrentNodeId on progress records pointing to removed nodes,
            // then re-point them to the start node (or delete if no start node exists yet).
            var startNodeId = await db.MapNodes
                .Where(n => n.IsStartNode && incomingNodeGuids.Contains(n.Id))
                .Select(n => (Guid?)n.Id)
                .FirstOrDefaultAsync();

            var affectedProgress = await db.UserMapProgresses
                .Include(p => p.UnlockedNodes)
                .Where(p => removedNodeIds.Contains(p.CurrentNodeId))
                .ToListAsync();

            foreach (var progress in affectedProgress)
            {
                if (startNodeId.HasValue)
                {
                    progress.CurrentNodeId = startNodeId.Value;
                    progress.CurrentEdgeId = null;
                    progress.DestinationNodeId = null;
                    progress.DistanceTraveledOnEdge = 0;
                }
                else
                {
                    db.UserMapProgresses.Remove(progress);
                }
            }

            // Remove unlocks for deleted nodes
            var staleLocks = await db.UserNodeUnlocks
                .Where(u => removedNodeIds.Contains(u.MapNodeId))
                .ToListAsync();
            db.UserNodeUnlocks.RemoveRange(staleLocks);
        }

        // ── Resolve incoming edge GUIDs ────────────────────────────────────────────
        var edgeIdMap = new Dictionary<string, Guid>(); // temp ID → assigned GUID
        var incomingEdgeGuids = new HashSet<Guid>();

        foreach (var e in payload.Edges ?? [])
        {
            if (Guid.TryParse(e.Id, out var guid))
                incomingEdgeGuids.Add(guid);
            else
            {
                guid = Guid.NewGuid();
                if (e.Id != null) edgeIdMap[e.Id] = guid;
                incomingEdgeGuids.Add(guid);
            }
        }

        // Null out CurrentEdgeId on progress records whose edge was removed
        var removedEdgeIds = await db.MapEdges
            .Where(e => !incomingEdgeGuids.Contains(e.Id))
            .Select(e => e.Id)
            .ToListAsync();

        if (removedEdgeIds.Count > 0)
        {
            var edgeProgress = await db.UserMapProgresses
                .Where(p => p.CurrentEdgeId.HasValue && removedEdgeIds.Contains(p.CurrentEdgeId.Value))
                .ToListAsync();
            foreach (var p in edgeProgress)
            {
                p.CurrentEdgeId = null;
                p.DestinationNodeId = null;
                p.DistanceTraveledOnEdge = 0;
            }
        }

        // ── Resolve incoming sub-entity GUIDs ─────────────────────────────────────
        var incomingBossGuids      = new HashSet<Guid>();
        var incomingDungeonGuids   = new HashSet<Guid>();
        var incomingChestGuids     = new HashSet<Guid>();
        var incomingCrossroadsGuids = new HashSet<Guid>();

        static Guid ResolveGuid(string? id, Dictionary<string, Guid>? tempMap = null)
        {
            if (tempMap != null && id != null && tempMap.TryGetValue(id, out var mapped)) return mapped;
            return Guid.TryParse(id, out var g) ? g : Guid.NewGuid();
        }

        foreach (var b  in payload.Bosses     ?? []) incomingBossGuids.Add(ResolveGuid(b.Id));
        foreach (var d  in payload.Dungeons   ?? []) incomingDungeonGuids.Add(ResolveGuid(d.Id));
        foreach (var c  in payload.Chests     ?? []) incomingChestGuids.Add(ResolveGuid(c.Id));
        foreach (var cr in payload.Crossroads ?? []) incomingCrossroadsGuids.Add(ResolveGuid(cr.Id));

        // ── Delete removed sub-entities + their user states ────────────────────────
        var removedBossIds = await db.Bosses
            .Where(b => !incomingBossGuids.Contains(b.Id)).Select(b => b.Id).ToListAsync();
        var removedDungeonIds = await db.DungeonPortals
            .Where(d => !incomingDungeonGuids.Contains(d.Id)).Select(d => d.Id).ToListAsync();
        var removedChestIds = await db.Chests
            .Where(c => !incomingChestGuids.Contains(c.Id)).Select(c => c.Id).ToListAsync();
        var removedCrossroadsIds = await db.Crossroads
            .Where(c => !incomingCrossroadsGuids.Contains(c.Id)).Select(c => c.Id).ToListAsync();

        static string ToSqlArray(IEnumerable<Guid> ids) =>
            $"ARRAY[{string.Join(",", ids.Select(id => $"'{id}'"))}]::uuid[]";

        if (removedBossIds.Count > 0)
        {
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"UserBossStates\" WHERE \"BossId\" = ANY({ToSqlArray(removedBossIds)});");
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"Bosses\" WHERE \"Id\" = ANY({ToSqlArray(removedBossIds)});");
        }
        if (removedDungeonIds.Count > 0)
        {
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"UserDungeonStates\" WHERE \"DungeonPortalId\" = ANY({ToSqlArray(removedDungeonIds)});");
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"DungeonFloors\" WHERE \"DungeonPortalId\" = ANY({ToSqlArray(removedDungeonIds)});");
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"DungeonPortals\" WHERE \"Id\" = ANY({ToSqlArray(removedDungeonIds)});");
        }
        if (removedChestIds.Count > 0)
        {
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"UserChestStates\" WHERE \"ChestId\" = ANY({ToSqlArray(removedChestIds)});");
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"Chests\" WHERE \"Id\" = ANY({ToSqlArray(removedChestIds)});");
        }
        if (removedCrossroadsIds.Count > 0)
        {
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"UserCrossroadsStates\" WHERE \"CrossroadsId\" = ANY({ToSqlArray(removedCrossroadsIds)});");
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"CrossroadsPaths\" WHERE \"CrossroadsId\" = ANY({ToSqlArray(removedCrossroadsIds)});");
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"Crossroads\" WHERE \"Id\" = ANY({ToSqlArray(removedCrossroadsIds)});");
        }

        // Flush EF-tracked deletions (stale unlocks, progress resets) before raw SQL deletes nodes/edges
        await db.SaveChangesAsync();

        if (removedEdgeIds.Count > 0)
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"MapEdges\" WHERE \"Id\" = ANY({ToSqlArray(removedEdgeIds)});");

        if (removedNodeIds.Count > 0)
            await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"MapNodes\" WHERE \"Id\" = ANY({ToSqlArray(removedNodeIds)});");

        // ── NODES (upsert) ─────────────────────────────────────────────────────────
        foreach (var n in payload.Nodes ?? [])
        {
            var guid = Guid.TryParse(n.Id, out var parsedGuid) ? parsedGuid : nodeIdMap[n.Id!];
            var worldZoneId = Guid.TryParse(n.WorldZoneId, out var wzGuid) ? (Guid?)wzGuid : null;

            if (!Enum.TryParse<MapNodeType>(n.Type, ignoreCase: true, out var nodeType))
                nodeType = MapNodeType.Zone;
            if (!Enum.TryParse<MapRegion>(n.Region, ignoreCase: true, out var region))
                region = MapRegion.Ashfield;

            var existing = await db.MapNodes.FindAsync(guid);
            if (existing is not null)
            {
                existing.Name             = n.Name ?? existing.Name;
                existing.Description      = n.Description;
                existing.Icon             = n.Icon ?? existing.Icon;
                existing.Type             = nodeType;
                existing.Region           = region;
                existing.PositionX        = (float)n.X;
                existing.PositionY        = (float)n.Y;
                existing.LevelRequirement = n.LevelReq;
                existing.RewardXp         = n.RewardXp;
                existing.IsStartNode      = n.IsStart;
                existing.IsHidden         = n.IsHidden;
                existing.WorldZoneId      = worldZoneId;
            }
            else
            {
                db.MapNodes.Add(new MapNode
                {
                    Id               = guid,
                    Name             = n.Name ?? "Unnamed",
                    Description      = n.Description,
                    Icon             = n.Icon ?? "❓",
                    Type             = nodeType,
                    Region           = region,
                    PositionX        = (float)n.X,
                    PositionY        = (float)n.Y,
                    LevelRequirement = n.LevelReq,
                    RewardXp         = n.RewardXp,
                    IsStartNode      = n.IsStart,
                    IsHidden         = n.IsHidden,
                    WorldZoneId      = worldZoneId,
                });
            }
        }

        await db.SaveChangesAsync();

        // ── EDGES (upsert) ─────────────────────────────────────────────────────────
        foreach (var e in payload.Edges ?? [])
        {
            var guid = Guid.TryParse(e.Id, out var parsedEdgeGuid) ? parsedEdgeGuid : edgeIdMap[e.Id!];

            var fromId = nodeIdMap.TryGetValue(e.FromNodeId ?? "", out var f) ? f
                : Guid.TryParse(e.FromNodeId, out var fg) ? fg : Guid.Empty;
            var toId = nodeIdMap.TryGetValue(e.ToNodeId ?? "", out var t) ? t
                : Guid.TryParse(e.ToNodeId, out var tg) ? tg : Guid.Empty;
            if (fromId == Guid.Empty || toId == Guid.Empty) continue;

            var existing = await db.MapEdges.FindAsync(guid);
            if (existing is not null)
            {
                existing.FromNodeId      = fromId;
                existing.ToNodeId        = toId;
                existing.DistanceKm      = e.DistanceKm;
                existing.IsBidirectional = e.Bidirectional;
            }
            else
            {
                db.MapEdges.Add(new MapEdge
                {
                    Id               = guid,
                    FromNodeId       = fromId,
                    ToNodeId         = toId,
                    DistanceKm       = e.DistanceKm,
                    IsBidirectional  = e.Bidirectional,
                });
            }
        }

        // ── BOSSES (upsert) ────────────────────────────────────────────────────────
        foreach (var b in payload.Bosses ?? [])
        {
            var guid = ResolveGuid(b.Id);
            var nodeId = nodeIdMap.TryGetValue(b.NodeId ?? "", out var nid) ? nid
                : Guid.TryParse(b.NodeId, out var ng) ? ng : Guid.Empty;
            if (nodeId == Guid.Empty) continue;

            var existing = await db.Bosses.FindAsync(guid);
            if (existing is not null)
            {
                existing.NodeId    = nodeId;
                existing.Name      = b.Name ?? existing.Name;
                existing.Icon      = b.Icon ?? existing.Icon;
                existing.MaxHp     = b.MaxHp;
                existing.RewardXp  = b.RewardXp;
                existing.TimerDays = b.TimerDays;
                existing.IsMini    = b.IsMini;
            }
            else
            {
                db.Bosses.Add(new Boss { Id = guid, NodeId = nodeId, Name = b.Name ?? "Unknown Boss",
                    Icon = b.Icon ?? "👹", MaxHp = b.MaxHp, RewardXp = b.RewardXp, TimerDays = b.TimerDays, IsMini = b.IsMini });
            }
        }

        // ── DUNGEONS (upsert) ──────────────────────────────────────────────────────
        foreach (var d in payload.Dungeons ?? [])
        {
            var dungeonId = ResolveGuid(d.Id);
            var nodeId = nodeIdMap.TryGetValue(d.NodeId ?? "", out var nid) ? nid
                : Guid.TryParse(d.NodeId, out var ng) ? ng : Guid.Empty;
            if (nodeId == Guid.Empty) continue;

            var existing = await db.DungeonPortals.Include(dp => dp.Floors).FirstOrDefaultAsync(dp => dp.Id == dungeonId);
            if (existing is not null)
            {
                existing.NodeId      = nodeId;
                existing.Name        = d.Name ?? existing.Name;
                existing.TotalFloors = d.TotalFloors;
                db.DungeonFloors.RemoveRange(existing.Floors);
            }
            else
            {
                existing = new DungeonPortal { Id = dungeonId, NodeId = nodeId, Name = d.Name ?? "Dungeon", TotalFloors = d.TotalFloors };
                db.DungeonPortals.Add(existing);
            }

            foreach (var fl in d.Floors ?? [])
            {
                if (!Enum.TryParse<ActivityType>(fl.RequiredActivity, ignoreCase: true, out var act))
                    act = ActivityType.Running;
                db.DungeonFloors.Add(new DungeonFloor { Id = Guid.NewGuid(), DungeonPortalId = dungeonId,
                    FloorNumber = fl.Floor, RequiredActivity = act, RequiredMinutes = fl.RequiredMinutes, RewardXp = fl.RewardXp });
            }
        }

        // ── CHESTS (upsert) ────────────────────────────────────────────────────────
        foreach (var c in payload.Chests ?? [])
        {
            var guid = ResolveGuid(c.Id);
            var nodeId = nodeIdMap.TryGetValue(c.NodeId ?? "", out var nid) ? nid
                : Guid.TryParse(c.NodeId, out var ng) ? ng : Guid.Empty;
            if (nodeId == Guid.Empty) continue;

            if (!Enum.TryParse<ChestRarity>(c.Rarity, ignoreCase: true, out var rarity)) rarity = ChestRarity.Common;

            var existing = await db.Chests.FindAsync(guid);
            if (existing is not null) { existing.NodeId = nodeId; existing.Rarity = rarity; existing.RewardXp = c.RewardXp; }
            else db.Chests.Add(new Chest { Id = guid, NodeId = nodeId, Rarity = rarity, RewardXp = c.RewardXp });
        }

        // ── CROSSROADS (upsert) ────────────────────────────────────────────────────
        foreach (var cr in payload.Crossroads ?? [])
        {
            var crossroadsId = ResolveGuid(cr.Id);
            var nodeId = nodeIdMap.TryGetValue(cr.NodeId ?? "", out var nid) ? nid
                : Guid.TryParse(cr.NodeId, out var ng) ? ng : Guid.Empty;
            if (nodeId == Guid.Empty) continue;

            var existing = await db.Crossroads.Include(x => x.Paths).FirstOrDefaultAsync(x => x.Id == crossroadsId);
            if (existing is not null)
            {
                existing.NodeId = nodeId;
                // Wipe user crossroads choices since paths are being replaced
                await db.Database.ExecuteSqlRawAsync($"DELETE FROM \"UserCrossroadsStates\" WHERE \"CrossroadsId\" = '{crossroadsId}';");
                db.CrossroadsPaths.RemoveRange(existing.Paths);
            }
            else
            {
                db.Crossroads.Add(new Crossroads { Id = crossroadsId, NodeId = nodeId });
            }

            foreach (var p in cr.Paths ?? [])
            {
                if (!Enum.TryParse<CrossroadsPathDifficulty>(p.Difficulty, ignoreCase: true, out var diff))
                    diff = CrossroadsPathDifficulty.Moderate;
                var leadsTo = nodeIdMap.TryGetValue(p.LeadsToNodeId ?? "", out var ltMapped) ? (Guid?)ltMapped
                    : Guid.TryParse(p.LeadsToNodeId, out var ltg) ? (Guid?)ltg : null;
                db.CrossroadsPaths.Add(new CrossroadsPath { Id = Guid.NewGuid(), CrossroadsId = crossroadsId,
                    Name = p.Name ?? "Path", DistanceKm = p.DistanceKm, Difficulty = diff,
                    EstimatedDays = p.EstimatedDays, RewardXp = p.RewardXp,
                    AdditionalRequirement = p.AdditionalRequirement, LeadsToNodeId = leadsTo });
            }
        }

        await db.SaveChangesAsync();
        return Ok(new { synced = true });
    }

    // -------------------------------------------------------------------------
    // MAP NODES
    // -------------------------------------------------------------------------

    [HttpGet("nodes")]
    public async Task<IActionResult> GetAllNodes()
    {
        var nodes = await db.MapNodes
            .Select(n => new
            {
                n.Id,
                n.Name,
                n.Description,
                n.Icon,
                n.Type,
                n.Region,
                n.PositionX,
                n.PositionY,
                n.LevelRequirement,
                n.RewardXp,
                n.IsStartNode,
                n.IsHidden,
                HasBoss = n.Boss != null,
                HasChest = n.Chest != null,
                HasDungeon = n.DungeonPortal != null,
                HasCrossroads = n.Crossroads != null,
                FloorCount = n.DungeonPortal != null ? n.DungeonPortal.Floors.Count : 0,
                PathCount = n.Crossroads != null ? n.Crossroads.Paths.Count : 0
            })
            .OrderBy(n => n.Name)
            .ToListAsync();

        return Ok(nodes);
    }

    [HttpGet("nodes/{id:guid}")]
    public async Task<IActionResult> GetNodeById(Guid id)
    {
        var node = await db.MapNodes
            .Include(n => n.Boss)
            .Include(n => n.Chest)
            .Include(n => n.DungeonPortal).ThenInclude(d => d!.Floors)
            .Include(n => n.Crossroads).ThenInclude(c => c!.Paths)
            .Where(n => n.Id == id)
            .FirstOrDefaultAsync();

        if (node is null) return NotFound();
        return Ok(node);
    }

    [HttpPost("nodes")]
    public async Task<IActionResult> CreateNode([FromBody] CreateMapNodeRequest req)
    {
        if (!Enum.TryParse<MapNodeType>(req.Type, ignoreCase: true, out var nodeType))
            return BadRequest($"Invalid Type. Valid values: {string.Join(", ", Enum.GetNames<MapNodeType>())}");

        if (!Enum.TryParse<MapRegion>(req.Region, ignoreCase: true, out var region))
            return BadRequest($"Invalid Region. Valid values: {string.Join(", ", Enum.GetNames<MapRegion>())}");

        var node = new MapNode
        {
            Id = Guid.NewGuid(),
            Name = req.Name,
            Description = req.Description,
            Icon = req.Icon,
            Type = nodeType,
            Region = region,
            PositionX = req.PositionX,
            PositionY = req.PositionY,
            LevelRequirement = req.LevelRequirement,
            RewardXp = req.RewardXp,
            IsStartNode = req.IsStartNode,
            IsHidden = req.IsHidden
        };

        db.MapNodes.Add(node);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetNodeById), new { id = node.Id }, node);
    }

    [HttpPut("nodes/{id:guid}")]
    public async Task<IActionResult> UpdateNode(Guid id, [FromBody] UpdateMapNodeRequest req)
    {
        var node = await db.MapNodes.FindAsync(id);
        if (node is null) return NotFound();

        if (!Enum.TryParse<MapNodeType>(req.Type, ignoreCase: true, out var nodeType))
            return BadRequest($"Invalid Type. Valid values: {string.Join(", ", Enum.GetNames<MapNodeType>())}");

        if (!Enum.TryParse<MapRegion>(req.Region, ignoreCase: true, out var region))
            return BadRequest($"Invalid Region. Valid values: {string.Join(", ", Enum.GetNames<MapRegion>())}");

        node.Name = req.Name;
        node.Description = req.Description;
        node.Icon = req.Icon;
        node.Type = nodeType;
        node.Region = region;
        node.PositionX = req.PositionX;
        node.PositionY = req.PositionY;
        node.LevelRequirement = req.LevelRequirement;
        node.RewardXp = req.RewardXp;
        node.IsStartNode = req.IsStartNode;
        node.IsHidden = req.IsHidden;

        await db.SaveChangesAsync();
        return Ok(node);
    }

    [HttpDelete("nodes/{id:guid}")]
    public async Task<IActionResult> DeleteNode(Guid id)
    {
        var node = await db.MapNodes
            .Include(n => n.Boss)
            .Include(n => n.Chest)
            .Include(n => n.DungeonPortal)
            .Include(n => n.Crossroads)
            .Where(n => n.Id == id)
            .FirstOrDefaultAsync();

        if (node is null) return NotFound();

        if (node.Boss is not null)
            return BadRequest("Cannot delete node: a Boss is attached. Delete the Boss first.");

        if (node.Chest is not null)
            return BadRequest("Cannot delete node: a Chest is attached. Delete the Chest first.");

        if (node.DungeonPortal is not null)
            return BadRequest("Cannot delete node: a DungeonPortal is attached. Delete the Dungeon first.");

        if (node.Crossroads is not null)
            return BadRequest("Cannot delete node: a Crossroads is attached. Delete the Crossroads first.");

        db.MapNodes.Remove(node);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // MAP EDGES
    // -------------------------------------------------------------------------

    [HttpGet("edges")]
    public async Task<IActionResult> GetAllEdges()
    {
        var edges = await db.MapEdges
            .Select(e => new
            {
                e.Id,
                e.FromNodeId,
                FromNodeName = e.FromNode.Name,
                e.ToNodeId,
                ToNodeName = e.ToNode.Name,
                e.DistanceKm,
                e.IsBidirectional
            })
            .OrderBy(e => e.FromNodeName)
            .ToListAsync();

        return Ok(edges);
    }

    [HttpPost("edges")]
    public async Task<IActionResult> CreateEdge([FromBody] CreateMapEdgeRequest req)
    {
        var fromExists = await db.MapNodes.AnyAsync(n => n.Id == req.FromNodeId);
        if (!fromExists) return BadRequest($"FromNodeId '{req.FromNodeId}' does not exist.");

        var toExists = await db.MapNodes.AnyAsync(n => n.Id == req.ToNodeId);
        if (!toExists) return BadRequest($"ToNodeId '{req.ToNodeId}' does not exist.");

        var edge = new MapEdge
        {
            Id = Guid.NewGuid(),
            FromNodeId = req.FromNodeId,
            ToNodeId = req.ToNodeId,
            DistanceKm = req.DistanceKm,
            IsBidirectional = req.IsBidirectional
        };

        db.MapEdges.Add(edge);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAllEdges), new { }, edge);
    }

    [HttpDelete("edges/{id:guid}")]
    public async Task<IActionResult> DeleteEdge(Guid id)
    {
        var edge = await db.MapEdges.FindAsync(id);
        if (edge is null) return NotFound();

        db.MapEdges.Remove(edge);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // BOSSES
    // -------------------------------------------------------------------------

    [HttpGet("bosses")]
    public async Task<IActionResult> GetAllBosses()
    {
        var bosses = await db.Bosses
            .Select(b => new
            {
                b.Id,
                b.NodeId,
                NodeName = b.Node.Name,
                b.Name,
                b.Icon,
                b.MaxHp,
                b.RewardXp,
                b.TimerDays,
                b.IsMini
            })
            .OrderBy(b => b.Name)
            .ToListAsync();

        return Ok(bosses);
    }

    [HttpGet("bosses/{id:guid}")]
    public async Task<IActionResult> GetBossById(Guid id)
    {
        var boss = await db.Bosses
            .Include(b => b.Node)
            .Where(b => b.Id == id)
            .FirstOrDefaultAsync();

        if (boss is null) return NotFound();
        return Ok(boss);
    }

    [HttpPost("bosses")]
    public async Task<IActionResult> CreateBoss([FromBody] CreateBossRequest req)
    {
        var node = await db.MapNodes
            .Include(n => n.Boss)
            .Where(n => n.Id == req.NodeId)
            .FirstOrDefaultAsync();

        if (node is null) return BadRequest($"NodeId '{req.NodeId}' does not exist.");

        if (node.Type != MapNodeType.Boss)
            return BadRequest($"Node type must be 'Boss'. Current type is '{node.Type}'. Update the node type first.");

        if (node.Boss is not null)
            return BadRequest("This node already has a Boss attached.");

        var boss = new Boss
        {
            Id = Guid.NewGuid(),
            NodeId = req.NodeId,
            Name = req.Name,
            Icon = req.Icon,
            MaxHp = req.MaxHp,
            RewardXp = req.RewardXp,
            TimerDays = req.TimerDays,
            IsMini = req.IsMini
        };

        db.Bosses.Add(boss);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetBossById), new { id = boss.Id }, boss);
    }

    [HttpPut("bosses/{id:guid}")]
    public async Task<IActionResult> UpdateBoss(Guid id, [FromBody] UpdateBossRequest req)
    {
        var boss = await db.Bosses.FindAsync(id);
        if (boss is null) return NotFound();

        boss.Name = req.Name;
        boss.Icon = req.Icon;
        boss.MaxHp = req.MaxHp;
        boss.RewardXp = req.RewardXp;
        boss.TimerDays = req.TimerDays;
        boss.IsMini = req.IsMini;

        await db.SaveChangesAsync();
        return Ok(boss);
    }

    [HttpDelete("bosses/{id:guid}")]
    public async Task<IActionResult> DeleteBoss(Guid id)
    {
        var boss = await db.Bosses.FindAsync(id);
        if (boss is null) return NotFound();

        db.Bosses.Remove(boss);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // DUNGEONS
    // -------------------------------------------------------------------------

    [HttpGet("dungeons")]
    public async Task<IActionResult> GetAllDungeons()
    {
        var dungeons = await db.DungeonPortals
            .Select(d => new
            {
                d.Id,
                d.NodeId,
                NodeName = d.Node.Name,
                d.Name,
                d.TotalFloors,
                FloorCount = d.Floors.Count
            })
            .OrderBy(d => d.Name)
            .ToListAsync();

        return Ok(dungeons);
    }

    [HttpGet("dungeons/{id:guid}")]
    public async Task<IActionResult> GetDungeonById(Guid id)
    {
        var dungeon = await db.DungeonPortals
            .Include(d => d.Node)
            .Include(d => d.Floors.OrderBy(f => f.FloorNumber))
            .Where(d => d.Id == id)
            .FirstOrDefaultAsync();

        if (dungeon is null) return NotFound();
        return Ok(dungeon);
    }

    [HttpPost("dungeons")]
    public async Task<IActionResult> CreateDungeon([FromBody] CreateDungeonRequest req)
    {
        var node = await db.MapNodes
            .Include(n => n.DungeonPortal)
            .Where(n => n.Id == req.NodeId)
            .FirstOrDefaultAsync();

        if (node is null) return BadRequest($"NodeId '{req.NodeId}' does not exist.");

        if (node.DungeonPortal is not null)
            return BadRequest("This node already has a DungeonPortal attached.");

        var dungeon = new DungeonPortal
        {
            Id = Guid.NewGuid(),
            NodeId = req.NodeId,
            Name = req.Name,
            TotalFloors = req.TotalFloors
        };

        db.DungeonPortals.Add(dungeon);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetDungeonById), new { id = dungeon.Id }, dungeon);
    }

    [HttpPut("dungeons/{id:guid}")]
    public async Task<IActionResult> UpdateDungeon(Guid id, [FromBody] UpdateDungeonRequest req)
    {
        var dungeon = await db.DungeonPortals.FindAsync(id);
        if (dungeon is null) return NotFound();

        dungeon.Name = req.Name;
        dungeon.TotalFloors = req.TotalFloors;

        await db.SaveChangesAsync();
        return Ok(dungeon);
    }

    [HttpDelete("dungeons/{id:guid}")]
    public async Task<IActionResult> DeleteDungeon(Guid id)
    {
        var dungeon = await db.DungeonPortals
            .Include(d => d.Floors)
            .Where(d => d.Id == id)
            .FirstOrDefaultAsync();

        if (dungeon is null) return NotFound();

        db.DungeonFloors.RemoveRange(dungeon.Floors);
        db.DungeonPortals.Remove(dungeon);
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("dungeons/{id:guid}/floors")]
    public async Task<IActionResult> AddDungeonFloor(Guid id, [FromBody] CreateDungeonFloorRequest req)
    {
        var dungeon = await db.DungeonPortals.FindAsync(id);
        if (dungeon is null) return NotFound();

        if (!Enum.TryParse<ActivityType>(req.RequiredActivity, ignoreCase: true, out var activityType))
            return BadRequest($"Invalid RequiredActivity. Valid values: {string.Join(", ", Enum.GetNames<ActivityType>())}");

        var floorExists = await db.DungeonFloors
            .AnyAsync(f => f.DungeonPortalId == id && f.FloorNumber == req.FloorNumber);

        if (floorExists)
            return BadRequest($"Floor number {req.FloorNumber} already exists in this dungeon.");

        var floor = new DungeonFloor
        {
            Id = Guid.NewGuid(),
            DungeonPortalId = id,
            FloorNumber = req.FloorNumber,
            RequiredActivity = activityType,
            RequiredMinutes = req.RequiredMinutes,
            RewardXp = req.RewardXp
        };

        db.DungeonFloors.Add(floor);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetDungeonById), new { id }, floor);
    }

    [HttpPut("dungeons/{id:guid}/floors/{floorNumber:int}")]
    public async Task<IActionResult> UpdateDungeonFloor(Guid id, int floorNumber, [FromBody] UpdateDungeonFloorRequest req)
    {
        var dungeon = await db.DungeonPortals.FindAsync(id);
        if (dungeon is null) return NotFound();

        var floor = await db.DungeonFloors
            .Where(f => f.DungeonPortalId == id && f.FloorNumber == floorNumber)
            .FirstOrDefaultAsync();

        if (floor is null) return NotFound();

        if (!Enum.TryParse<ActivityType>(req.RequiredActivity, ignoreCase: true, out var activityType))
            return BadRequest($"Invalid RequiredActivity. Valid values: {string.Join(", ", Enum.GetNames<ActivityType>())}");

        floor.RequiredActivity = activityType;
        floor.RequiredMinutes = req.RequiredMinutes;
        floor.RewardXp = req.RewardXp;

        await db.SaveChangesAsync();
        return Ok(floor);
    }

    [HttpDelete("dungeons/{id:guid}/floors/{floorNumber:int}")]
    public async Task<IActionResult> DeleteDungeonFloor(Guid id, int floorNumber)
    {
        var dungeon = await db.DungeonPortals.FindAsync(id);
        if (dungeon is null) return NotFound();

        var floor = await db.DungeonFloors
            .Where(f => f.DungeonPortalId == id && f.FloorNumber == floorNumber)
            .FirstOrDefaultAsync();

        if (floor is null) return NotFound();

        db.DungeonFloors.Remove(floor);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // CHESTS
    // -------------------------------------------------------------------------

    [HttpGet("chests")]
    public async Task<IActionResult> GetAllChests()
    {
        var chests = await db.Chests
            .Select(c => new
            {
                c.Id,
                c.NodeId,
                NodeName = c.Node.Name,
                c.Rarity,
                c.RewardXp
            })
            .OrderBy(c => c.NodeName)
            .ToListAsync();

        return Ok(chests);
    }

    [HttpGet("chests/{id:guid}")]
    public async Task<IActionResult> GetChestById(Guid id)
    {
        var chest = await db.Chests
            .Include(c => c.Node)
            .Where(c => c.Id == id)
            .FirstOrDefaultAsync();

        if (chest is null) return NotFound();
        return Ok(chest);
    }

    [HttpPost("chests")]
    public async Task<IActionResult> CreateChest([FromBody] CreateChestRequest req)
    {
        if (!Enum.TryParse<ChestRarity>(req.Rarity, ignoreCase: true, out var rarity))
            return BadRequest($"Invalid Rarity. Valid values: {string.Join(", ", Enum.GetNames<ChestRarity>())}");

        var node = await db.MapNodes
            .Include(n => n.Chest)
            .Where(n => n.Id == req.NodeId)
            .FirstOrDefaultAsync();

        if (node is null) return BadRequest($"NodeId '{req.NodeId}' does not exist.");

        if (node.Chest is not null)
            return BadRequest("This node already has a Chest attached.");

        var chest = new Chest
        {
            Id = Guid.NewGuid(),
            NodeId = req.NodeId,
            Rarity = rarity,
            RewardXp = req.RewardXp
        };

        db.Chests.Add(chest);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetChestById), new { id = chest.Id }, chest);
    }

    [HttpPut("chests/{id:guid}")]
    public async Task<IActionResult> UpdateChest(Guid id, [FromBody] UpdateChestRequest req)
    {
        var chest = await db.Chests.FindAsync(id);
        if (chest is null) return NotFound();

        if (!Enum.TryParse<ChestRarity>(req.Rarity, ignoreCase: true, out var rarity))
            return BadRequest($"Invalid Rarity. Valid values: {string.Join(", ", Enum.GetNames<ChestRarity>())}");

        chest.Rarity = rarity;
        chest.RewardXp = req.RewardXp;

        await db.SaveChangesAsync();
        return Ok(chest);
    }

    [HttpDelete("chests/{id:guid}")]
    public async Task<IActionResult> DeleteChest(Guid id)
    {
        var chest = await db.Chests.FindAsync(id);
        if (chest is null) return NotFound();

        db.Chests.Remove(chest);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // CROSSROADS
    // -------------------------------------------------------------------------

    [HttpGet("crossroads")]
    public async Task<IActionResult> GetAllCrossroads()
    {
        var crossroads = await db.Crossroads
            .Select(c => new
            {
                c.Id,
                c.NodeId,
                NodeName = c.Node.Name,
                PathCount = c.Paths.Count
            })
            .OrderBy(c => c.NodeName)
            .ToListAsync();

        return Ok(crossroads);
    }

    [HttpGet("crossroads/{id:guid}")]
    public async Task<IActionResult> GetCrossroadsById(Guid id)
    {
        var crossroads = await db.Crossroads
            .Include(c => c.Node)
            .Include(c => c.Paths)
            .Where(c => c.Id == id)
            .FirstOrDefaultAsync();

        if (crossroads is null) return NotFound();
        return Ok(crossroads);
    }

    [HttpPost("crossroads")]
    public async Task<IActionResult> CreateCrossroads([FromBody] CreateCrossroadsRequest req)
    {
        var node = await db.MapNodes
            .Include(n => n.Crossroads)
            .Where(n => n.Id == req.NodeId)
            .FirstOrDefaultAsync();

        if (node is null) return BadRequest($"NodeId '{req.NodeId}' does not exist.");

        if (node.Crossroads is not null)
            return BadRequest("This node already has a Crossroads attached.");

        var crossroads = new Crossroads
        {
            Id = Guid.NewGuid(),
            NodeId = req.NodeId
        };

        db.Crossroads.Add(crossroads);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetCrossroadsById), new { id = crossroads.Id }, crossroads);
    }

    [HttpDelete("crossroads/{id:guid}")]
    public async Task<IActionResult> DeleteCrossroads(Guid id)
    {
        var crossroads = await db.Crossroads
            .Include(c => c.Paths)
            .Where(c => c.Id == id)
            .FirstOrDefaultAsync();

        if (crossroads is null) return NotFound();

        db.CrossroadsPaths.RemoveRange(crossroads.Paths);
        db.Crossroads.Remove(crossroads);
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("crossroads/{id:guid}/paths")]
    public async Task<IActionResult> AddCrossroadsPath(Guid id, [FromBody] CreateCrossroadsPathRequest req)
    {
        var crossroads = await db.Crossroads.FindAsync(id);
        if (crossroads is null) return NotFound();

        if (!Enum.TryParse<CrossroadsPathDifficulty>(req.Difficulty, ignoreCase: true, out var difficulty))
            return BadRequest($"Invalid Difficulty. Valid values: {string.Join(", ", Enum.GetNames<CrossroadsPathDifficulty>())}");

        if (req.LeadsToNodeId.HasValue)
        {
            var targetExists = await db.MapNodes.AnyAsync(n => n.Id == req.LeadsToNodeId.Value);
            if (!targetExists)
                return BadRequest($"LeadsToNodeId '{req.LeadsToNodeId}' does not exist.");
        }

        var path = new CrossroadsPath
        {
            Id = Guid.NewGuid(),
            CrossroadsId = id,
            Name = req.Name,
            DistanceKm = req.DistanceKm,
            Difficulty = difficulty,
            EstimatedDays = req.EstimatedDays,
            RewardXp = req.RewardXp,
            AdditionalRequirement = req.AdditionalRequirement,
            LeadsToNodeId = req.LeadsToNodeId
        };

        db.CrossroadsPaths.Add(path);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetCrossroadsById), new { id }, path);
    }

    [HttpPut("crossroads/{id:guid}/paths/{pathId:guid}")]
    public async Task<IActionResult> UpdateCrossroadsPath(Guid id, Guid pathId, [FromBody] UpdateCrossroadsPathRequest req)
    {
        var crossroads = await db.Crossroads.FindAsync(id);
        if (crossroads is null) return NotFound();

        var path = await db.CrossroadsPaths
            .Where(p => p.CrossroadsId == id && p.Id == pathId)
            .FirstOrDefaultAsync();

        if (path is null) return NotFound();

        if (!Enum.TryParse<CrossroadsPathDifficulty>(req.Difficulty, ignoreCase: true, out var difficulty))
            return BadRequest($"Invalid Difficulty. Valid values: {string.Join(", ", Enum.GetNames<CrossroadsPathDifficulty>())}");

        if (req.LeadsToNodeId.HasValue)
        {
            var targetExists = await db.MapNodes.AnyAsync(n => n.Id == req.LeadsToNodeId.Value);
            if (!targetExists)
                return BadRequest($"LeadsToNodeId '{req.LeadsToNodeId}' does not exist.");
        }

        path.Name = req.Name;
        path.DistanceKm = req.DistanceKm;
        path.Difficulty = difficulty;
        path.EstimatedDays = req.EstimatedDays;
        path.RewardXp = req.RewardXp;
        path.AdditionalRequirement = req.AdditionalRequirement;
        path.LeadsToNodeId = req.LeadsToNodeId;

        await db.SaveChangesAsync();
        return Ok(path);
    }

    [HttpDelete("crossroads/{id:guid}/paths/{pathId:guid}")]
    public async Task<IActionResult> DeleteCrossroadsPath(Guid id, Guid pathId)
    {
        var crossroads = await db.Crossroads.FindAsync(id);
        if (crossroads is null) return NotFound();

        var path = await db.CrossroadsPaths
            .Where(p => p.CrossroadsId == id && p.Id == pathId)
            .FirstOrDefaultAsync();

        if (path is null) return NotFound();

        db.CrossroadsPaths.Remove(path);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // WORLD ZONES (overworld sync)
    // -------------------------------------------------------------------------

    [HttpPost("sync-world")]
    public async Task<IActionResult> SyncWorld([FromBody] SyncWorldRequest payload)
    {
        // ── Resolve incoming zone GUIDs ────────────────────────────────────────
        var zoneIdMap = new Dictionary<string, Guid>(); // temp ID → assigned GUID
        var incomingZoneGuids = new HashSet<Guid>();

        foreach (var z in payload.Zones ?? [])
        {
            if (Guid.TryParse(z.Id, out var guid))
                incomingZoneGuids.Add(guid);
            else
            {
                guid = Guid.NewGuid();
                if (z.Id != null) zoneIdMap[z.Id] = guid;
                incomingZoneGuids.Add(guid);
            }
        }

        // ── Resolve incoming edge GUIDs ────────────────────────────────────────
        var edgeIdMap = new Dictionary<string, Guid>();
        var incomingEdgeGuids = new HashSet<Guid>();

        foreach (var e in payload.Edges ?? [])
        {
            if (Guid.TryParse(e.Id, out var guid))
                incomingEdgeGuids.Add(guid);
            else
            {
                guid = Guid.NewGuid();
                if (e.Id != null) edgeIdMap[e.Id] = guid;
                incomingEdgeGuids.Add(guid);
            }
        }

        // ── Delete removed edges ───────────────────────────────────────────────
        var removedEdgeIds = await db.WorldZoneEdges
            .Where(e => !incomingEdgeGuids.Contains(e.Id))
            .Select(e => e.Id)
            .ToListAsync();

        if (removedEdgeIds.Count > 0)
        {
            var edgeProgress = await db.UserWorldProgresses
                .Where(p => p.CurrentEdgeId.HasValue && removedEdgeIds.Contains(p.CurrentEdgeId.Value))
                .ToListAsync();
            foreach (var p in edgeProgress)
            {
                p.CurrentEdgeId = null;
                p.DestinationZoneId = null;
                p.DistanceTraveledOnEdge = 0;
            }

            await db.SaveChangesAsync();

            static string ToSqlArray(IEnumerable<Guid> ids) =>
                $"ARRAY[{string.Join(",", ids.Select(id => $"'{id}'"))}]::uuid[]";

            await db.Database.ExecuteSqlRawAsync(
                $"DELETE FROM \"WorldZoneEdges\" WHERE \"Id\" = ANY({ToSqlArray(removedEdgeIds)});");
        }

        // ── Delete removed zones (only if not referenced by any UserWorldProgress) ──
        var removedZoneIds = await db.WorldZones
            .Where(z => !incomingZoneGuids.Contains(z.Id))
            .Select(z => z.Id)
            .ToListAsync();

        if (removedZoneIds.Count > 0)
        {
            // Re-point progress records whose current zone was removed to the start zone
            var startZoneId = incomingZoneGuids.Count > 0
                ? await db.WorldZones
                    .Where(z => z.IsStartZone && incomingZoneGuids.Contains(z.Id))
                    .Select(z => (Guid?)z.Id)
                    .FirstOrDefaultAsync()
                : null;

            var affectedProgress = await db.UserWorldProgresses
                .Where(p => removedZoneIds.Contains(p.CurrentZoneId))
                .ToListAsync();

            foreach (var p in affectedProgress)
            {
                if (startZoneId.HasValue)
                {
                    p.CurrentZoneId = startZoneId.Value;
                    p.CurrentEdgeId = null;
                    p.DestinationZoneId = null;
                    p.DistanceTraveledOnEdge = 0;
                }
                else
                {
                    db.UserWorldProgresses.Remove(p);
                }
            }

            // Remove zone unlocks for deleted zones
            var staleUnlocks = await db.UserZoneUnlocks
                .Where(u => removedZoneIds.Contains(u.WorldZoneId))
                .ToListAsync();
            db.UserZoneUnlocks.RemoveRange(staleUnlocks);

            await db.SaveChangesAsync();

            static string ToSqlArray(IEnumerable<Guid> ids) =>
                $"ARRAY[{string.Join(",", ids.Select(id => $"'{id}'"))}]::uuid[]";

            await db.Database.ExecuteSqlRawAsync(
                $"DELETE FROM \"WorldZones\" WHERE \"Id\" = ANY({ToSqlArray(removedZoneIds)});");
        }

        // ── ZONES (upsert) ─────────────────────────────────────────────────────
        foreach (var z in payload.Zones ?? [])
        {
            var guid = Guid.TryParse(z.Id, out var parsedGuid) ? parsedGuid : zoneIdMap[z.Id!];

            var existing = await db.WorldZones.FindAsync(guid);
            if (existing is not null)
            {
                existing.Name            = z.Name ?? existing.Name;
                existing.Description     = z.Description;
                existing.Icon            = z.Icon ?? existing.Icon;
                existing.Region          = z.Region ?? existing.Region;
                existing.Tier            = z.Tier;
                existing.PositionX       = (float)z.X;
                existing.PositionY       = (float)z.Y;
                existing.LevelRequirement = z.LevelReq;
                existing.TotalXp         = z.TotalXp;
                existing.TotalDistanceKm = z.TotalDistanceKm;
                existing.IsCrossroads    = z.IsCrossroads;
                existing.IsStartZone     = z.IsStart;
                existing.IsHidden        = z.IsHidden;
            }
            else
            {
                db.WorldZones.Add(new Domain.Entities.WorldZone
                {
                    Id               = guid,
                    Name             = z.Name ?? "Unnamed Zone",
                    Description      = z.Description,
                    Icon             = z.Icon ?? "❓",
                    Region           = z.Region ?? string.Empty,
                    Tier             = z.Tier,
                    PositionX        = (float)z.X,
                    PositionY        = (float)z.Y,
                    LevelRequirement = z.LevelReq,
                    TotalXp          = z.TotalXp,
                    TotalDistanceKm  = z.TotalDistanceKm,
                    IsCrossroads     = z.IsCrossroads,
                    IsStartZone      = z.IsStart,
                    IsHidden         = z.IsHidden,
                });
            }
        }

        await db.SaveChangesAsync();

        // ── EDGES (upsert) ─────────────────────────────────────────────────────
        foreach (var e in payload.Edges ?? [])
        {
            var guid = Guid.TryParse(e.Id, out var parsedEdgeGuid) ? parsedEdgeGuid : edgeIdMap[e.Id!];

            var fromId = zoneIdMap.TryGetValue(e.FromZoneId ?? "", out var f) ? f
                : Guid.TryParse(e.FromZoneId, out var fg) ? fg : Guid.Empty;
            var toId = zoneIdMap.TryGetValue(e.ToZoneId ?? "", out var t) ? t
                : Guid.TryParse(e.ToZoneId, out var tg) ? tg : Guid.Empty;
            if (fromId == Guid.Empty || toId == Guid.Empty) continue;

            var existing = await db.WorldZoneEdges.FindAsync(guid);
            if (existing is not null)
            {
                existing.FromZoneId      = fromId;
                existing.ToZoneId        = toId;
                existing.DistanceKm      = e.DistanceKm;
                existing.IsBidirectional = e.Bidirectional;
            }
            else
            {
                db.WorldZoneEdges.Add(new Domain.Entities.WorldZoneEdge
                {
                    Id               = guid,
                    FromZoneId       = fromId,
                    ToZoneId         = toId,
                    DistanceKm       = e.DistanceKm,
                    IsBidirectional  = e.Bidirectional,
                });
            }
        }

        await db.SaveChangesAsync();

        var syncedZones = await db.WorldZones
            .Where(z => incomingZoneGuids.Contains(z.Id))
            .ToListAsync();
        var syncedEdges = await db.WorldZoneEdges
            .Where(e => incomingEdgeGuids.Contains(e.Id))
            .ToListAsync();

        return Ok(new { synced = true, zones = syncedZones.Count, edges = syncedEdges.Count });
    }
}

// =============================================================================
// REQUEST RECORDS
// =============================================================================

// --- Map Nodes ---
public record CreateMapNodeRequest(
    string Name,
    string? Description,
    string Icon,
    string Type,
    string Region,
    float PositionX,
    float PositionY,
    int LevelRequirement,
    int RewardXp,
    bool IsStartNode,
    bool IsHidden);

public record UpdateMapNodeRequest(
    string Name,
    string? Description,
    string Icon,
    string Type,
    string Region,
    float PositionX,
    float PositionY,
    int LevelRequirement,
    int RewardXp,
    bool IsStartNode,
    bool IsHidden);

// --- Map Edges ---
public record CreateMapEdgeRequest(
    Guid FromNodeId,
    Guid ToNodeId,
    double DistanceKm,
    bool IsBidirectional);

// --- Bosses ---
public record CreateBossRequest(
    Guid NodeId,
    string Name,
    string Icon,
    int MaxHp,
    int RewardXp,
    int TimerDays,
    bool IsMini);

public record UpdateBossRequest(
    string Name,
    string Icon,
    int MaxHp,
    int RewardXp,
    int TimerDays,
    bool IsMini);

// --- Dungeons ---
public record CreateDungeonRequest(
    Guid NodeId,
    string Name,
    int TotalFloors);

public record UpdateDungeonRequest(
    string Name,
    int TotalFloors);

public record CreateDungeonFloorRequest(
    int FloorNumber,
    string RequiredActivity,
    int RequiredMinutes,
    int RewardXp);

public record UpdateDungeonFloorRequest(
    string RequiredActivity,
    int RequiredMinutes,
    int RewardXp);

// --- Chests ---
public record CreateChestRequest(
    Guid NodeId,
    string Rarity,
    int RewardXp);

public record UpdateChestRequest(
    string Rarity,
    int RewardXp);

// --- Crossroads ---
public record CreateCrossroadsRequest(Guid NodeId);

public record CreateCrossroadsPathRequest(
    string Name,
    double DistanceKm,
    string Difficulty,
    int EstimatedDays,
    int RewardXp,
    string? AdditionalRequirement,
    Guid? LeadsToNodeId);

public record UpdateCrossroadsPathRequest(
    string Name,
    double DistanceKm,
    string Difficulty,
    int EstimatedDays,
    int RewardXp,
    string? AdditionalRequirement,
    Guid? LeadsToNodeId);

// ── Bulk sync records (used by HTML admin panel) ──────────────────────────────
public record MapSyncPayload(
    List<SyncNode>? Nodes,
    List<SyncEdge>? Edges,
    List<SyncBoss>? Bosses,
    List<SyncDungeon>? Dungeons,
    List<SyncChest>? Chests,
    List<SyncCrossroads>? Crossroads);

public record SyncNode(
    string? Id, string? Name, string? Description, string? Icon,
    string? Type, string? Region,
    double X, double Y,
    int LevelReq, int RewardXp,
    bool IsStart, bool IsHidden,
    string? WorldZoneId = null);

public record SyncEdge(
    string? Id, string? FromNodeId, string? ToNodeId,
    double DistanceKm, bool Bidirectional);

public record SyncBoss(
    string? Id, string? NodeId, string? Name, string? Icon,
    int MaxHp, int RewardXp, int TimerDays, bool IsMini);

public record SyncDungeon(
    string? Id, string? NodeId, string? Name, int TotalFloors,
    List<SyncDungeonFloor>? Floors);

public record SyncDungeonFloor(
    string? Id, int Floor, string? RequiredActivity,
    int RequiredMinutes, int RewardXp);

public record SyncChest(
    string? Id, string? NodeId, string? Rarity, int RewardXp);

public record SyncCrossroads(
    string? Id, string? NodeId, List<SyncCrossroadsPath>? Paths);

public record SyncCrossroadsPath(
    string? Id, string? Name, double DistanceKm, string? Difficulty,
    int EstimatedDays, int RewardXp,
    string? AdditionalRequirement, string? LeadsToNodeId);

// ── World Zone sync records ───────────────────────────────────────────────────
public class SyncWorldRequest
{
    public List<WorldZonePayload> Zones { get; set; } = [];
    public List<WorldZoneEdgePayload> Edges { get; set; } = [];
}

public class WorldZonePayload
{
    public string? Id { get; set; }
    public string? Name { get; set; }
    public string? Description { get; set; }
    public string? Icon { get; set; }
    public string? Region { get; set; }
    public int Tier { get; set; }
    public double X { get; set; }
    public double Y { get; set; }
    public int LevelReq { get; set; }
    public int TotalXp { get; set; }
    public double TotalDistanceKm { get; set; }
    public bool IsCrossroads { get; set; }
    public bool IsStart { get; set; }
    public bool IsHidden { get; set; }
}

public class WorldZoneEdgePayload
{
    public string? Id { get; set; }
    public string? FromZoneId { get; set; }
    public string? ToZoneId { get; set; }
    public double DistanceKm { get; set; }
    public bool Bidirectional { get; set; }
}
