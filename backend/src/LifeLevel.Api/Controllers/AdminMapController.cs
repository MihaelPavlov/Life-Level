using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using LifeLevel.Modules.Adventure.Dungeons.Domain.Enums;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Enums;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.Modules.Map.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.SharedKernel.Enums;
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
                icon            = z.Emoji,
                region          = z.Region.Name,
                regionId        = z.RegionId.ToString(),
                tier            = z.Tier,
                type            = z.Type.ToString().ToLowerInvariant(),
                levelReq        = z.LevelRequirement,
                totalXp         = z.XpReward,
                totalDistanceKm = z.DistanceKm,
                isBoss          = z.IsBoss,
                isStart         = z.IsStartZone,
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
    // WORLDS (CRUD)
    // -------------------------------------------------------------------------

    [HttpGet("worlds")]
    public async Task<IActionResult> GetAllWorlds()
    {
        var worlds = await db.Worlds
            .OrderByDescending(w => w.IsActive)
            .ThenBy(w => w.Name)
            .Select(w => new
            {
                id          = w.Id,
                name        = w.Name,
                isActive    = w.IsActive,
                createdAt   = w.CreatedAt,
                regionCount = db.Regions.Count(r => r.WorldId == w.Id),
                zoneCount   = db.WorldZones.Count(z => z.Region.WorldId == w.Id),
            })
            .ToListAsync();
        return Ok(worlds);
    }

    [HttpGet("worlds/{id:guid}")]
    public async Task<IActionResult> GetWorldById(Guid id)
    {
        var world = await db.Worlds
            .Where(w => w.Id == id)
            .Select(w => new
            {
                id          = w.Id,
                name        = w.Name,
                isActive    = w.IsActive,
                createdAt   = w.CreatedAt,
                regionCount = db.Regions.Count(r => r.WorldId == w.Id),
                zoneCount   = db.WorldZones.Count(z => z.Region.WorldId == w.Id),
            })
            .FirstOrDefaultAsync();
        if (world is null) return NotFound();
        return Ok(world);
    }

    [HttpPost("worlds")]
    public async Task<IActionResult> CreateWorld([FromBody] CreateWorldRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            return BadRequest("Name is required.");

        var world = new World
        {
            Id = Guid.NewGuid(),
            Name = req.Name.Trim(),
            IsActive = req.IsActive,
            CreatedAt = DateTime.UtcNow,
        };

        if (req.IsActive)
        {
            // One-active invariant: flip all others off
            var active = await db.Worlds.Where(w => w.IsActive).ToListAsync();
            foreach (var w in active) w.IsActive = false;
        }

        db.Worlds.Add(world);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetWorldById), new { id = world.Id }, new { world.Id });
    }

    [HttpPut("worlds/{id:guid}")]
    public async Task<IActionResult> UpdateWorld(Guid id, [FromBody] UpdateWorldRequest req)
    {
        var world = await db.Worlds.FindAsync(id);
        if (world is null) return NotFound();

        if (string.IsNullOrWhiteSpace(req.Name))
            return BadRequest("Name is required.");

        world.Name = req.Name.Trim();

        if (req.IsActive && !world.IsActive)
        {
            // Flipping this world ON — turn all other worlds off
            var active = await db.Worlds.Where(w => w.IsActive && w.Id != id).ToListAsync();
            foreach (var w in active) w.IsActive = false;
        }
        world.IsActive = req.IsActive;

        await db.SaveChangesAsync();
        return Ok(new { world.Id });
    }

    [HttpDelete("worlds/{id:guid}")]
    public async Task<IActionResult> DeleteWorld(Guid id)
    {
        var world = await db.Worlds.FindAsync(id);
        if (world is null) return NotFound();

        var regionCount = await db.Regions.CountAsync(r => r.WorldId == id);
        if (regionCount > 0)
            return Conflict($"Cannot delete world: {regionCount} region(s) exist. Delete them first.");

        var zoneCount = await db.WorldZones.CountAsync(z => z.Region.WorldId == id);
        if (zoneCount > 0)
            return Conflict($"Cannot delete world: {zoneCount} zone(s) exist. Delete them first.");

        var progressCount = await db.UserWorldProgresses.CountAsync(p => p.WorldId == id);
        if (progressCount > 0)
            return Conflict($"Cannot delete world: {progressCount} user(s) have progress in it.");

        db.Worlds.Remove(world);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // REGIONS (CRUD)
    // -------------------------------------------------------------------------

    [HttpGet("worlds/{worldId:guid}/regions")]
    public async Task<IActionResult> GetRegionsByWorld(Guid worldId)
    {
        if (!await db.Worlds.AnyAsync(w => w.Id == worldId))
            return NotFound();

        var regions = await db.Regions
            .Where(r => r.WorldId == worldId)
            .OrderBy(r => r.ChapterIndex)
            .ThenBy(r => r.Name)
            .Select(r => new
            {
                id               = r.Id,
                worldId          = r.WorldId,
                name             = r.Name,
                emoji            = r.Emoji,
                theme            = r.Theme.ToString().ToLowerInvariant(),
                chapterIndex     = r.ChapterIndex,
                levelRequirement = r.LevelRequirement,
                lore             = r.Lore,
                zoneCount        = db.WorldZones.Count(z => z.RegionId == r.Id),
            })
            .ToListAsync();

        return Ok(regions);
    }

    [HttpGet("regions/{id:guid}")]
    public async Task<IActionResult> GetRegionById(Guid id)
    {
        var region = await db.Regions
            .Where(r => r.Id == id)
            .Select(r => new
            {
                id               = r.Id,
                worldId          = r.WorldId,
                name             = r.Name,
                emoji            = r.Emoji,
                theme            = r.Theme.ToString().ToLowerInvariant(),
                chapterIndex     = r.ChapterIndex,
                levelRequirement = r.LevelRequirement,
                lore             = r.Lore,
                zoneCount        = db.WorldZones.Count(z => z.RegionId == r.Id),
            })
            .FirstOrDefaultAsync();
        if (region is null) return NotFound();
        return Ok(region);
    }

    [HttpPost("regions")]
    public async Task<IActionResult> CreateRegion([FromBody] CreateRegionRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            return BadRequest("Name is required.");

        if (!await db.Worlds.AnyAsync(w => w.Id == req.WorldId))
            return BadRequest($"World '{req.WorldId}' not found.");

        if (!Enum.TryParse<RegionTheme>(req.Theme, ignoreCase: true, out var theme))
            return BadRequest($"Invalid Theme. Valid values: {string.Join(", ", Enum.GetNames<RegionTheme>())}");

        var region = new Region
        {
            Id = Guid.NewGuid(),
            WorldId = req.WorldId,
            Name = req.Name.Trim(),
            Emoji = req.Emoji ?? string.Empty,
            Theme = theme,
            ChapterIndex = req.ChapterIndex,
            LevelRequirement = req.LevelRequirement,
            Lore = req.Lore ?? string.Empty,
        };

        db.Regions.Add(region);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetRegionById), new { id = region.Id }, new { region.Id });
    }

    [HttpPut("regions/{id:guid}")]
    public async Task<IActionResult> UpdateRegion(Guid id, [FromBody] UpdateRegionRequest req)
    {
        var region = await db.Regions.FindAsync(id);
        if (region is null) return NotFound();

        if (string.IsNullOrWhiteSpace(req.Name))
            return BadRequest("Name is required.");

        if (!Enum.TryParse<RegionTheme>(req.Theme, ignoreCase: true, out var theme))
            return BadRequest($"Invalid Theme. Valid values: {string.Join(", ", Enum.GetNames<RegionTheme>())}");

        region.Name = req.Name.Trim();
        region.Emoji = req.Emoji ?? string.Empty;
        region.Theme = theme;
        region.ChapterIndex = req.ChapterIndex;
        region.LevelRequirement = req.LevelRequirement;
        region.Lore = req.Lore ?? string.Empty;

        await db.SaveChangesAsync();
        return Ok(new { region.Id });
    }

    [HttpDelete("regions/{id:guid}")]
    public async Task<IActionResult> DeleteRegion(Guid id)
    {
        var region = await db.Regions.FindAsync(id);
        if (region is null) return NotFound();

        var zoneCount = await db.WorldZones.CountAsync(z => z.RegionId == id);
        if (zoneCount > 0)
            return Conflict($"Cannot delete region: {zoneCount} zone(s) belong to it.");

        db.Regions.Remove(region);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // MAP NODES
    // -------------------------------------------------------------------------

    [HttpGet("nodes")]
    public async Task<IActionResult> GetAllNodes([FromQuery] Guid? zoneId = null)
    {
        var query = db.MapNodes.AsQueryable();
        if (zoneId.HasValue)
            query = query.Where(n => n.WorldZoneId == zoneId.Value);

        var nodes = await query
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
                n.WorldZoneId
            })
            .OrderBy(n => n.Name)
            .ToListAsync();

        var nodeIds = nodes.Select(n => n.Id).ToHashSet();
        var bossNodeIds = await db.Bosses
            .Where(b => b.NodeId.HasValue && nodeIds.Contains(b.NodeId.Value))
            .Select(b => b.NodeId!.Value)
            .ToHashSetAsync();
        var chestNodeIds = await db.Chests.Where(c => nodeIds.Contains(c.NodeId)).Select(c => c.NodeId).ToHashSetAsync();
        var dungeonNodeIds = await db.DungeonPortals.Where(d => nodeIds.Contains(d.NodeId)).Select(d => new { d.NodeId, FloorCount = d.Floors.Count }).ToListAsync();
        var crossroadsNodeIds = await db.Crossroads.Where(c => nodeIds.Contains(c.NodeId)).Select(c => new { c.NodeId, PathCount = c.Paths.Count }).ToListAsync();

        var result = nodes.Select(n => new
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
            n.WorldZoneId,
            HasBoss = bossNodeIds.Contains(n.Id),
            HasChest = chestNodeIds.Contains(n.Id),
            HasDungeon = dungeonNodeIds.Any(d => d.NodeId == n.Id),
            HasCrossroads = crossroadsNodeIds.Any(c => c.NodeId == n.Id),
            FloorCount = dungeonNodeIds.FirstOrDefault(d => d.NodeId == n.Id)?.FloorCount ?? 0,
            PathCount = crossroadsNodeIds.FirstOrDefault(c => c.NodeId == n.Id)?.PathCount ?? 0
        }).ToList();

        return Ok(result);
    }

    [HttpGet("nodes/{id:guid}")]
    public async Task<IActionResult> GetNodeById(Guid id)
    {
        var node = await db.MapNodes
            .Where(n => n.Id == id)
            .Select(n => new
            {
                n.Id, n.Name, n.Description, n.Icon,
                type   = n.Type.ToString(),
                region = n.Region.ToString(),
                n.PositionX, n.PositionY,
                n.LevelRequirement, n.RewardXp,
                n.IsStartNode, n.IsHidden, n.WorldZoneId
            })
            .FirstOrDefaultAsync();

        if (node is null) return NotFound();

        var boss = await db.Bosses
            .Where(b => b.NodeId == id)
            .Select(b => new { b.Id, b.NodeId, b.Name, b.Icon, b.MaxHp, b.RewardXp, b.TimerDays, b.IsMini })
            .FirstOrDefaultAsync();

        var chest = await db.Chests
            .Where(c => c.NodeId == id)
            .Select(c => new { c.Id, c.NodeId, rarity = c.Rarity.ToString(), c.RewardXp })
            .FirstOrDefaultAsync();

        var dungeon = await db.DungeonPortals
            .Where(d => d.NodeId == id)
            .Select(d => new
            {
                d.Id, d.NodeId, d.Name, d.TotalFloors,
                floors = d.Floors.OrderBy(f => f.FloorNumber).Select(f => new
                {
                    f.Id, f.FloorNumber,
                    requiredActivity = f.RequiredActivity.ToString(),
                    f.RequiredMinutes, f.RewardXp
                }).ToList()
            })
            .FirstOrDefaultAsync();

        var crossroadsRaw = await db.Crossroads
            .Include(c => c.Paths)
            .Where(c => c.NodeId == id)
            .FirstOrDefaultAsync();

        var crossroads = crossroadsRaw is null ? null : new
        {
            crossroadsRaw.Id,
            crossroadsRaw.NodeId,
            paths = crossroadsRaw.Paths.Select(p => new
            {
                p.Id, p.Name,
                difficulty = p.Difficulty.ToString(),
                p.DistanceKm, p.EstimatedDays, p.RewardXp,
                p.AdditionalRequirement, p.LeadsToNodeId
            }).ToList()
        };

        return Ok(new { node, boss, chest, dungeon, crossroads });
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
            IsHidden = req.IsHidden,
            WorldZoneId = req.WorldZoneId
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
        node.WorldZoneId = req.WorldZoneId;

        await db.SaveChangesAsync();
        return Ok(node);
    }

    [HttpDelete("nodes/{id:guid}")]
    public async Task<IActionResult> DeleteNode(Guid id)
    {
        var node = await db.MapNodes.FindAsync(id);
        if (node is null) return NotFound();

        var hasBoss = await db.Bosses.AnyAsync(b => b.NodeId == id);
        if (hasBoss)
            return BadRequest("Cannot delete node: a Boss is attached. Delete the Boss first.");

        var hasChest = await db.Chests.AnyAsync(c => c.NodeId == id);
        if (hasChest)
            return BadRequest("Cannot delete node: a Chest is attached. Delete the Chest first.");

        var hasDungeon = await db.DungeonPortals.AnyAsync(d => d.NodeId == id);
        if (hasDungeon)
            return BadRequest("Cannot delete node: a DungeonPortal is attached. Delete the Dungeon first.");

        var hasCrossroads = await db.Crossroads.AnyAsync(c => c.NodeId == id);
        if (hasCrossroads)
            return BadRequest("Cannot delete node: a Crossroads is attached. Delete the Crossroads first.");

        // Cascade: null out progress records traveling on any edge connected to this node
        var connectedEdges = await db.MapEdges
            .Where(e => e.FromNodeId == id || e.ToNodeId == id)
            .ToListAsync();

        if (connectedEdges.Count > 0)
        {
            var connectedEdgeIds = connectedEdges.Select(e => e.Id).ToList();
            var travelingProgress = await db.UserMapProgresses
                .Where(p => p.CurrentEdgeId.HasValue && connectedEdgeIds.Contains(p.CurrentEdgeId.Value))
                .ToListAsync();
            foreach (var p in travelingProgress)
            {
                p.CurrentEdgeId = null;
                p.DestinationNodeId = null;
                p.DistanceTraveledOnEdge = 0;
            }
            db.MapEdges.RemoveRange(connectedEdges);
        }

        // Null out progress records with this node as current or destination
        var nodeProgress = await db.UserMapProgresses
            .Where(p => p.CurrentNodeId == id || p.DestinationNodeId == id)
            .ToListAsync();
        foreach (var p in nodeProgress)
        {
            if (p.CurrentNodeId == id) p.CurrentNodeId = Guid.Empty;
            if (p.DestinationNodeId == id) p.DestinationNodeId = null;
        }

        // Remove node unlocks
        var unlocks = await db.UserNodeUnlocks.Where(u => u.MapNodeId == id).ToListAsync();
        db.UserNodeUnlocks.RemoveRange(unlocks);

        db.MapNodes.Remove(node);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // MAP EDGES
    // -------------------------------------------------------------------------

    [HttpGet("edges")]
    public async Task<IActionResult> GetAllEdges([FromQuery] Guid? zoneId = null)
    {
        var query = db.MapEdges.AsQueryable();
        if (zoneId.HasValue)
        {
            query = query.Where(e =>
                e.FromNode.WorldZoneId == zoneId.Value ||
                e.ToNode.WorldZoneId == zoneId.Value);
        }

        var edges = await query
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

    [HttpPut("edges/{id:guid}")]
    public async Task<IActionResult> UpdateEdge(Guid id, [FromBody] UpdateMapEdgeRequest req)
    {
        var edge = await db.MapEdges.FindAsync(id);
        if (edge is null) return NotFound();

        edge.DistanceKm      = req.DistanceKm;
        edge.IsBidirectional = req.IsBidirectional;

        await db.SaveChangesAsync();
        return Ok(new { edge.Id });
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
    public async Task<IActionResult> GetAllBosses([FromQuery] Guid? zoneId = null)
    {
        var query = db.Bosses.AsQueryable();
        if (zoneId.HasValue)
        {
            var zoneNodeIds = await db.MapNodes
                .Where(n => n.WorldZoneId == zoneId.Value)
                .Select(n => n.Id)
                .ToListAsync();
            // Boss.NodeId is nullable — world-zone bosses leave it null.
            query = query.Where(b => b.NodeId.HasValue && zoneNodeIds.Contains(b.NodeId.Value));
        }

        var bosses = await query.ToListAsync();
        var nodeIds = bosses.Where(b => b.NodeId.HasValue).Select(b => b.NodeId!.Value).ToHashSet();
        var nodeNames = await db.MapNodes
            .Where(n => nodeIds.Contains(n.Id))
            .Select(n => new { n.Id, n.Name })
            .ToListAsync();
        var nodeNameMap = nodeNames.ToDictionary(n => n.Id, n => n.Name);

        var result = bosses.OrderBy(b => b.Name).Select(b => new
        {
            b.Id,
            b.NodeId,
            NodeName = b.NodeId.HasValue ? nodeNameMap.GetValueOrDefault(b.NodeId.Value, "") : "",
            b.Name,
            b.Icon,
            b.MaxHp,
            b.RewardXp,
            b.TimerDays,
            b.IsMini
        }).ToList();

        return Ok(result);
    }

    [HttpGet("bosses/{id:guid}")]
    public async Task<IActionResult> GetBossById(Guid id)
    {
        var boss = await db.Bosses.FindAsync(id);
        if (boss is null) return NotFound();
        var node = await db.MapNodes.FindAsync(boss.NodeId);
        return Ok(new { boss, node });
    }

    [HttpPost("bosses")]
    public async Task<IActionResult> CreateBoss([FromBody] CreateBossRequest req)
    {
        var node = await db.MapNodes.FindAsync(req.NodeId);

        if (node is null) return BadRequest($"NodeId '{req.NodeId}' does not exist.");

        if (node.Type != MapNodeType.Boss)
            return BadRequest($"Node type must be 'Boss'. Current type is '{node.Type}'. Update the node type first.");

        var existingBoss = await db.Bosses.AnyAsync(b => b.NodeId == req.NodeId);
        if (existingBoss)
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
    public async Task<IActionResult> GetAllDungeons([FromQuery] Guid? zoneId = null)
    {
        var query = db.DungeonPortals.Include(d => d.Floors).AsQueryable();
        if (zoneId.HasValue)
        {
            var zoneNodeIds = await db.MapNodes
                .Where(n => n.WorldZoneId == zoneId.Value)
                .Select(n => n.Id)
                .ToListAsync();
            query = query.Where(d => zoneNodeIds.Contains(d.NodeId));
        }

        var dungeons = await query.ToListAsync();
        var nodeIds = dungeons.Select(d => d.NodeId).ToHashSet();
        var nodeNames = await db.MapNodes
            .Where(n => nodeIds.Contains(n.Id))
            .Select(n => new { n.Id, n.Name })
            .ToListAsync();
        var nodeNameMap = nodeNames.ToDictionary(n => n.Id, n => n.Name);

        var result = dungeons.OrderBy(d => d.Name).Select(d => new
        {
            d.Id,
            d.NodeId,
            NodeName = nodeNameMap.GetValueOrDefault(d.NodeId, ""),
            d.Name,
            d.TotalFloors,
            FloorCount = d.Floors.Count
        }).ToList();

        return Ok(result);
    }

    [HttpGet("dungeons/{id:guid}")]
    public async Task<IActionResult> GetDungeonById(Guid id)
    {
        var dungeon = await db.DungeonPortals
            .Include(d => d.Floors.OrderBy(f => f.FloorNumber))
            .Where(d => d.Id == id)
            .FirstOrDefaultAsync();

        if (dungeon is null) return NotFound();
        var node = await db.MapNodes.FindAsync(dungeon.NodeId);
        return Ok(new
        {
            dungeon = new
            {
                dungeon.Id,
                dungeon.NodeId,
                dungeon.Name,
                dungeon.TotalFloors,
                floors = dungeon.Floors.Select(f => new
                {
                    f.Id,
                    f.FloorNumber,
                    requiredActivity = f.RequiredActivity.ToString(),
                    f.RequiredMinutes,
                    f.RewardXp
                }).ToList()
            },
            node = node is null ? null : new { node.Id, node.Name, node.Icon }
        });
    }

    [HttpPost("dungeons")]
    public async Task<IActionResult> CreateDungeon([FromBody] CreateDungeonRequest req)
    {
        var node = await db.MapNodes.FindAsync(req.NodeId);

        if (node is null) return BadRequest($"NodeId '{req.NodeId}' does not exist.");

        var existingDungeon = await db.DungeonPortals.AnyAsync(d => d.NodeId == req.NodeId);
        if (existingDungeon)
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
        return CreatedAtAction(nameof(GetDungeonById), new { id = dungeon.Id },
            new { dungeon.Id, dungeon.NodeId, dungeon.Name, dungeon.TotalFloors, floors = Array.Empty<object>() });
    }

    [HttpPut("dungeons/{id:guid}")]
    public async Task<IActionResult> UpdateDungeon(Guid id, [FromBody] UpdateDungeonRequest req)
    {
        var dungeon = await db.DungeonPortals.FindAsync(id);
        if (dungeon is null) return NotFound();

        dungeon.Name = req.Name;
        dungeon.TotalFloors = req.TotalFloors;

        await db.SaveChangesAsync();
        return Ok(new { dungeon.Id, dungeon.NodeId, dungeon.Name, dungeon.TotalFloors });
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
        return CreatedAtAction(nameof(GetDungeonById), new { id },
            new { floor.Id, floor.DungeonPortalId, floor.FloorNumber, requiredActivity = floor.RequiredActivity.ToString(), floor.RequiredMinutes, floor.RewardXp });
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
        return Ok(new { floor.Id, floor.DungeonPortalId, floor.FloorNumber, requiredActivity = floor.RequiredActivity.ToString(), floor.RequiredMinutes, floor.RewardXp });
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
    public async Task<IActionResult> GetAllChests([FromQuery] Guid? zoneId = null)
    {
        var query = db.Chests.AsQueryable();
        if (zoneId.HasValue)
        {
            var zoneNodeIds = await db.MapNodes
                .Where(n => n.WorldZoneId == zoneId.Value)
                .Select(n => n.Id)
                .ToListAsync();
            query = query.Where(c => zoneNodeIds.Contains(c.NodeId));
        }

        var chests = await query.ToListAsync();
        var nodeIds = chests.Select(c => c.NodeId).ToHashSet();
        var nodeNames = await db.MapNodes
            .Where(n => nodeIds.Contains(n.Id))
            .Select(n => new { n.Id, n.Name })
            .ToListAsync();
        var nodeNameMap = nodeNames.ToDictionary(n => n.Id, n => n.Name);

        var result = chests.OrderBy(c => nodeNameMap.GetValueOrDefault(c.NodeId, "")).Select(c => new
        {
            c.Id,
            c.NodeId,
            NodeName = nodeNameMap.GetValueOrDefault(c.NodeId, ""),
            c.Rarity,
            c.RewardXp
        }).ToList();

        return Ok(result);
    }

    [HttpGet("chests/{id:guid}")]
    public async Task<IActionResult> GetChestById(Guid id)
    {
        var chest = await db.Chests.FindAsync(id);
        if (chest is null) return NotFound();
        var node = await db.MapNodes.FindAsync(chest.NodeId);
        return Ok(new { chest, node });
    }

    [HttpPost("chests")]
    public async Task<IActionResult> CreateChest([FromBody] CreateChestRequest req)
    {
        if (!Enum.TryParse<ChestRarity>(req.Rarity, ignoreCase: true, out var rarity))
            return BadRequest($"Invalid Rarity. Valid values: {string.Join(", ", Enum.GetNames<ChestRarity>())}");

        var node = await db.MapNodes.FindAsync(req.NodeId);

        if (node is null) return BadRequest($"NodeId '{req.NodeId}' does not exist.");

        var existingChest = await db.Chests.AnyAsync(c => c.NodeId == req.NodeId);
        if (existingChest)
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
    public async Task<IActionResult> GetAllCrossroads([FromQuery] Guid? zoneId = null)
    {
        var query = db.Crossroads.Include(c => c.Paths).AsQueryable();
        if (zoneId.HasValue)
        {
            var zoneNodeIds = await db.MapNodes
                .Where(n => n.WorldZoneId == zoneId.Value)
                .Select(n => n.Id)
                .ToListAsync();
            query = query.Where(c => zoneNodeIds.Contains(c.NodeId));
        }

        var crossroadsList = await query.ToListAsync();
        var nodeIds = crossroadsList.Select(c => c.NodeId).ToHashSet();
        var nodeNames = await db.MapNodes
            .Where(n => nodeIds.Contains(n.Id))
            .Select(n => new { n.Id, n.Name })
            .ToListAsync();
        var nodeNameMap = nodeNames.ToDictionary(n => n.Id, n => n.Name);

        var result = crossroadsList.OrderBy(c => nodeNameMap.GetValueOrDefault(c.NodeId, "")).Select(c => new
        {
            c.Id,
            c.NodeId,
            NodeName = nodeNameMap.GetValueOrDefault(c.NodeId, ""),
            PathCount = c.Paths.Count
        }).ToList();

        return Ok(result);
    }

    [HttpGet("crossroads/{id:guid}")]
    public async Task<IActionResult> GetCrossroadsById(Guid id)
    {
        var crossroads = await db.Crossroads
            .Include(c => c.Paths)
            .Where(c => c.Id == id)
            .FirstOrDefaultAsync();

        if (crossroads is null) return NotFound();
        var node = await db.MapNodes.FindAsync(crossroads.NodeId);
        return Ok(new
        {
            crossroads = new
            {
                crossroads.Id,
                crossroads.NodeId,
                paths = crossroads.Paths.Select(p => new
                {
                    p.Id,
                    p.Name,
                    difficulty = p.Difficulty.ToString(),
                    p.DistanceKm,
                    p.EstimatedDays,
                    p.RewardXp,
                    p.AdditionalRequirement,
                    p.LeadsToNodeId
                }).ToList()
            },
            node = node is null ? null : new { node.Id, node.Name, node.Icon }
        });
    }

    [HttpPost("crossroads")]
    public async Task<IActionResult> CreateCrossroads([FromBody] CreateCrossroadsRequest req)
    {
        var node = await db.MapNodes.FindAsync(req.NodeId);

        if (node is null) return BadRequest($"NodeId '{req.NodeId}' does not exist.");

        var existingCrossroads = await db.Crossroads.AnyAsync(c => c.NodeId == req.NodeId);
        if (existingCrossroads)
            return BadRequest("This node already has a Crossroads attached.");

        var crossroads = new Crossroads
        {
            Id = Guid.NewGuid(),
            NodeId = req.NodeId
        };

        db.Crossroads.Add(crossroads);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetCrossroadsById), new { id = crossroads.Id },
            new { crossroads.Id, crossroads.NodeId, paths = Array.Empty<object>() });
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
        return CreatedAtAction(nameof(GetCrossroadsById), new { id },
            new { path.Id, path.CrossroadsId, path.Name, difficulty = path.Difficulty.ToString(), path.DistanceKm, path.EstimatedDays, path.RewardXp, path.AdditionalRequirement, path.LeadsToNodeId });
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
        return Ok(new { path.Id, path.CrossroadsId, path.Name, difficulty = path.Difficulty.ToString(), path.DistanceKm, path.EstimatedDays, path.RewardXp, path.AdditionalRequirement, path.LeadsToNodeId });
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
    // WORLD ZONES (individual CRUD)
    // -------------------------------------------------------------------------

    [HttpGet("world-zones")]
    public async Task<IActionResult> GetAllWorldZones(
        [FromQuery] Guid? worldId = null,
        [FromQuery] Guid? regionId = null)
    {
        var query = db.WorldZones.AsQueryable();
        if (worldId.HasValue)
            query = query.Where(z => z.Region.WorldId == worldId.Value);
        if (regionId.HasValue)
            query = query.Where(z => z.RegionId == regionId.Value);

        var zones = await query
            .OrderBy(z => z.Name)
            .Select(z => new
            {
                id              = z.Id,
                name            = z.Name,
                description     = z.Description,
                icon            = z.Emoji,
                region          = z.Region.Name,
                regionId        = z.RegionId,
                tier            = z.Tier,
                type            = z.Type.ToString().ToLowerInvariant(),
                levelReq        = z.LevelRequirement,
                totalXp         = z.XpReward,
                totalDistanceKm = z.DistanceKm,
                isBoss          = z.IsBoss,
                isStart         = z.IsStartZone,
                worldId         = z.Region.WorldId,
            })
            .ToListAsync();
        return Ok(zones);
    }

    [HttpGet("world-zones/{id:guid}")]
    public async Task<IActionResult> GetWorldZoneById(Guid id)
    {
        var zone = await db.WorldZones
            .Include(z => z.Region)
            .FirstOrDefaultAsync(z => z.Id == id);
        if (zone is null) return NotFound();

        var nodeCount = await db.MapNodes.CountAsync(n => n.WorldZoneId == id);

        return Ok(new
        {
            id              = zone.Id,
            name            = zone.Name,
            description     = zone.Description,
            icon            = zone.Emoji,
            region          = zone.Region?.Name ?? string.Empty,
            regionId        = zone.RegionId,
            tier            = zone.Tier,
            type            = zone.Type.ToString().ToLowerInvariant(),
            levelReq        = zone.LevelRequirement,
            totalXp         = zone.XpReward,
            totalDistanceKm = zone.DistanceKm,
            isBoss          = zone.IsBoss,
            isStart         = zone.IsStartZone,
            worldId         = zone.Region?.WorldId,
            nodeCount,
        });
    }

    [HttpPost("world-zones")]
    public async Task<IActionResult> CreateWorldZone([FromBody] CreateWorldZoneRequest req)
    {
        var worldId = req.WorldId;
        if (!worldId.HasValue || worldId == Guid.Empty)
        {
            worldId = await db.Worlds
                .Where(w => w.IsActive)
                .Select(w => (Guid?)w.Id)
                .FirstOrDefaultAsync();

            if (worldId is null)
                return BadRequest("No active World found. Create a World first or provide a WorldId.");
        }
        else if (!await db.Worlds.AnyAsync(w => w.Id == worldId.Value))
        {
            return BadRequest("World not found.");
        }

        // Resolve Region: prefer RegionId; fall back to lookup by (WorldId, RegionName)
        Guid regionId;
        if (req.RegionId.HasValue && req.RegionId != Guid.Empty)
        {
            var exists = await db.Regions.AnyAsync(r => r.Id == req.RegionId.Value && r.WorldId == worldId.Value);
            if (!exists) return BadRequest($"Region '{req.RegionId}' not found in world.");
            regionId = req.RegionId.Value;
        }
        else if (!string.IsNullOrWhiteSpace(req.RegionName))
        {
            var region = await db.Regions
                .Where(r => r.WorldId == worldId.Value && r.Name == req.RegionName)
                .Select(r => (Guid?)r.Id)
                .FirstOrDefaultAsync();
            if (region is null)
                return BadRequest($"Region '{req.RegionName}' not found in the selected world.");
            regionId = region.Value;
        }
        else
        {
            return BadRequest("Either RegionId or RegionName must be provided.");
        }

        // Parse Type (default Entry)
        var zoneType = WorldZoneType.Entry;
        if (!string.IsNullOrWhiteSpace(req.Type))
        {
            if (!Enum.TryParse<WorldZoneType>(req.Type, ignoreCase: true, out zoneType))
                return BadRequest($"Invalid Type. Valid values: {string.Join(", ", Enum.GetNames<WorldZoneType>())}");
        }

        // Maintain IsBoss ↔ Type==Boss consistency
        var isBoss = req.IsBoss;
        if (zoneType == WorldZoneType.Boss) isBoss = true;
        else if (isBoss && string.IsNullOrWhiteSpace(req.Type)) zoneType = WorldZoneType.Boss;

        var zone = new WorldZoneEntity
        {
            Id              = Guid.NewGuid(),
            Name            = req.Name,
            Description     = req.Description,
            Emoji           = req.Icon,
            RegionId        = regionId,
            Tier            = req.Tier,
            Type            = zoneType,
            LevelRequirement = req.LevelReq,
            XpReward        = req.TotalXp,
            DistanceKm      = req.TotalDistanceKm,
            IsBoss          = isBoss,
            IsStartZone     = req.IsStart,
        };

        db.WorldZones.Add(zone);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetWorldZoneById), new { id = zone.Id }, new { zone.Id });
    }

    [HttpPut("world-zones/{id:guid}")]
    public async Task<IActionResult> UpdateWorldZone(Guid id, [FromBody] UpdateWorldZoneRequest req)
    {
        var zone = await db.WorldZones.FindAsync(id);
        if (zone is null) return NotFound();

        // Resolve Region: allow switching by ID or by Name (within the zone's current World,
        // reached via the zone's current Region).
        var zoneWorldId = await db.Regions
            .Where(r => r.Id == zone.RegionId)
            .Select(r => r.WorldId)
            .FirstOrDefaultAsync();

        if (req.RegionId.HasValue && req.RegionId != Guid.Empty)
        {
            var exists = await db.Regions.AnyAsync(r => r.Id == req.RegionId.Value && r.WorldId == zoneWorldId);
            if (!exists) return BadRequest($"Region '{req.RegionId}' not found in world.");
            zone.RegionId = req.RegionId.Value;
        }
        else if (!string.IsNullOrWhiteSpace(req.RegionName))
        {
            var region = await db.Regions
                .Where(r => r.WorldId == zoneWorldId && r.Name == req.RegionName)
                .Select(r => (Guid?)r.Id)
                .FirstOrDefaultAsync();
            if (region is null)
                return BadRequest($"Region '{req.RegionName}' not found in the zone's world.");
            zone.RegionId = region.Value;
        }

        // Parse Type (keep existing if not provided)
        var zoneType = zone.Type;
        if (!string.IsNullOrWhiteSpace(req.Type))
        {
            if (!Enum.TryParse<WorldZoneType>(req.Type, ignoreCase: true, out zoneType))
                return BadRequest($"Invalid Type. Valid values: {string.Join(", ", Enum.GetNames<WorldZoneType>())}");
        }

        // Maintain IsBoss ↔ Type==Boss consistency
        var isBoss = req.IsBoss;
        if (zoneType == WorldZoneType.Boss) isBoss = true;
        else if (isBoss && string.IsNullOrWhiteSpace(req.Type)) zoneType = WorldZoneType.Boss;

        zone.Name            = req.Name;
        zone.Description     = req.Description;
        zone.Emoji           = req.Icon;
        zone.Tier            = req.Tier;
        zone.Type            = zoneType;
        zone.LevelRequirement = req.LevelReq;
        zone.XpReward        = req.TotalXp;
        zone.DistanceKm      = req.TotalDistanceKm;
        zone.IsBoss          = isBoss;
        zone.IsStartZone     = req.IsStart;

        await db.SaveChangesAsync();
        return Ok(new { zone.Id });
    }

    [HttpDelete("world-zones/{id:guid}")]
    public async Task<IActionResult> DeleteWorldZone(Guid id)
    {
        var zone = await db.WorldZones.FindAsync(id);
        if (zone is null) return NotFound();

        var nodeCount = await db.MapNodes.CountAsync(n => n.WorldZoneId == id);
        if (nodeCount > 0)
            return BadRequest($"Cannot delete zone: {nodeCount} node(s) are assigned to it. Reassign or delete them first.");

        var edges = await db.WorldZoneEdges
            .Where(e => e.FromZoneId == id || e.ToZoneId == id)
            .ToListAsync();
        db.WorldZoneEdges.RemoveRange(edges);

        db.WorldZones.Remove(zone);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // WORLD ZONE EDGES (individual CRUD)
    // -------------------------------------------------------------------------

    [HttpGet("world-zone-edges")]
    public async Task<IActionResult> GetAllWorldZoneEdges([FromQuery] Guid? zoneId = null)
    {
        var query = db.WorldZoneEdges.AsQueryable();
        if (zoneId.HasValue)
            query = query.Where(e => e.FromZoneId == zoneId.Value || e.ToZoneId == zoneId.Value);

        var zoneNames = await db.WorldZones
            .Select(z => new { z.Id, z.Name, Icon = z.Emoji })
            .ToListAsync();

        var edges = await query.ToListAsync();

        var result = edges.Select(e => new
        {
            id            = e.Id,
            fromZoneId    = e.FromZoneId,
            fromZoneName  = zoneNames.FirstOrDefault(z => z.Id == e.FromZoneId)?.Name ?? e.FromZoneId.ToString(),
            fromZoneIcon  = zoneNames.FirstOrDefault(z => z.Id == e.FromZoneId)?.Icon ?? "",
            toZoneId      = e.ToZoneId,
            toZoneName    = zoneNames.FirstOrDefault(z => z.Id == e.ToZoneId)?.Name ?? e.ToZoneId.ToString(),
            toZoneIcon    = zoneNames.FirstOrDefault(z => z.Id == e.ToZoneId)?.Icon ?? "",
            distanceKm      = e.DistanceKm,
            isBidirectional = e.IsBidirectional,
        }).ToList();

        return Ok(result);
    }

    [HttpPost("world-zone-edges")]
    public async Task<IActionResult> CreateWorldZoneEdge([FromBody] CreateWorldZoneEdgeRequest req)
    {
        if (!await db.WorldZones.AnyAsync(z => z.Id == req.FromZoneId))
            return BadRequest("FromZoneId not found.");
        if (!await db.WorldZones.AnyAsync(z => z.Id == req.ToZoneId))
            return BadRequest("ToZoneId not found.");

        var duplicate = await db.WorldZoneEdges.AnyAsync(e =>
            (e.FromZoneId == req.FromZoneId && e.ToZoneId == req.ToZoneId) ||
            (e.FromZoneId == req.ToZoneId   && e.ToZoneId == req.FromZoneId));
        if (duplicate)
            return BadRequest("An edge between these two zones already exists.");

        var edge = new WorldZoneEdge
        {
            Id              = Guid.NewGuid(),
            FromZoneId      = req.FromZoneId,
            ToZoneId        = req.ToZoneId,
            DistanceKm      = req.DistanceKm,
            IsBidirectional = req.IsBidirectional,
        };

        db.WorldZoneEdges.Add(edge);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetAllWorldZoneEdges), new { }, new { edge.Id });
    }

    [HttpPut("world-zone-edges/{id:guid}")]
    public async Task<IActionResult> UpdateWorldZoneEdge(Guid id, [FromBody] UpdateWorldZoneEdgeRequest req)
    {
        var edge = await db.WorldZoneEdges.FindAsync(id);
        if (edge is null) return NotFound();

        edge.DistanceKm      = req.DistanceKm;
        edge.IsBidirectional = req.IsBidirectional;

        await db.SaveChangesAsync();
        return Ok(new { edge.Id });
    }

    [HttpDelete("world-zone-edges/{id:guid}")]
    public async Task<IActionResult> DeleteWorldZoneEdge(Guid id)
    {
        var edge = await db.WorldZoneEdges.FindAsync(id);
        if (edge is null) return NotFound();

        // Null out CurrentEdgeId on any UserWorldProgress traversing this edge
        var affectedProgress = await db.UserWorldProgresses
            .Where(p => p.CurrentEdgeId == id)
            .ToListAsync();
        foreach (var p in affectedProgress)
        {
            p.CurrentEdgeId = null;
            p.DestinationZoneId = null;
            p.DistanceTraveledOnEdge = 0;
        }

        db.WorldZoneEdges.Remove(edge);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // -------------------------------------------------------------------------
    // WORLD ZONES (overworld sync)
    // -------------------------------------------------------------------------

    [HttpPost("sync-world")]
    public async Task<IActionResult> SyncWorld([FromBody] SyncWorldRequest payload)
    {
        // Bulk sync doesn't carry per-zone RegionId yet. Pick the first region
        // in the active world as a default so new zones still get a valid FK.
        // Individual zone CRUD endpoints let the admin reassign the region.
        var fallbackRegionId = await db.Regions
            .Where(r => r.World.IsActive)
            .OrderBy(r => r.ChapterIndex)
            .Select(r => (Guid?)r.Id)
            .FirstOrDefaultAsync();

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

            // Parse Type (default Entry)
            var zoneType = WorldZoneType.Entry;
            if (!string.IsNullOrWhiteSpace(z.Type))
            {
                Enum.TryParse<WorldZoneType>(z.Type, ignoreCase: true, out zoneType);
            }

            // Maintain IsBoss ↔ Type==Boss consistency
            var isBoss = zoneType == WorldZoneType.Boss;

            var existing = await db.WorldZones.FindAsync(guid);
            if (existing is not null)
            {
                existing.Name            = z.Name ?? existing.Name;
                existing.Description     = z.Description;
                existing.Emoji           = z.Icon ?? existing.Emoji;
                existing.Tier            = z.Tier;
                existing.Type            = zoneType;
                existing.LevelRequirement = z.LevelReq;
                existing.XpReward        = z.TotalXp;
                existing.DistanceKm      = z.TotalDistanceKm;
                existing.IsBoss          = isBoss;
                existing.IsStartZone     = z.IsStart;
            }
            else
            {
                if (fallbackRegionId is null)
                    return BadRequest("No regions exist — seed at least one region before creating zones via sync.");
                db.WorldZones.Add(new WorldZoneEntity
                {
                    Id               = guid,
                    Name             = z.Name ?? "Unnamed Zone",
                    Description      = z.Description,
                    Emoji            = z.Icon ?? "❓",
                    RegionId         = fallbackRegionId.Value,
                    Tier             = z.Tier,
                    Type             = zoneType,
                    LevelRequirement = z.LevelReq,
                    XpReward         = z.TotalXp,
                    DistanceKm       = z.TotalDistanceKm,
                    IsBoss           = isBoss,
                    IsStartZone      = z.IsStart,
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
                db.WorldZoneEdges.Add(new WorldZoneEdge
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
    bool IsHidden,
    Guid? WorldZoneId = null);

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
    bool IsHidden,
    Guid? WorldZoneId = null);

// --- Map Edges ---
public record CreateMapEdgeRequest(
    Guid FromNodeId,
    Guid ToNodeId,
    double DistanceKm,
    bool IsBidirectional);

public record UpdateMapEdgeRequest(
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

// --- Worlds (individual CRUD) ---
public record CreateWorldRequest(string Name, bool IsActive);
public record UpdateWorldRequest(string Name, bool IsActive);

// --- Regions (individual CRUD) ---
public record CreateRegionRequest(
    Guid WorldId,
    string Name,
    string? Emoji,
    string Theme,
    int ChapterIndex,
    int LevelRequirement,
    string? Lore);

public record UpdateRegionRequest(
    string Name,
    string? Emoji,
    string Theme,
    int ChapterIndex,
    int LevelRequirement,
    string? Lore);

// --- World Zones (individual CRUD) ---
public record CreateWorldZoneRequest(
    string Name,
    string? Description,
    string Icon,
    string? RegionName,
    Guid? RegionId,
    int Tier,
    int LevelReq,
    int TotalXp,
    double TotalDistanceKm,
    bool IsBoss,
    bool IsStart,
    string? Type = null,
    Guid? WorldId = null);

public record UpdateWorldZoneRequest(
    string Name,
    string? Description,
    string Icon,
    string? RegionName,
    Guid? RegionId,
    int Tier,
    int LevelReq,
    int TotalXp,
    double TotalDistanceKm,
    bool IsBoss,
    bool IsStart,
    string? Type = null);

// --- World Zone Edges (individual CRUD) ---
public record CreateWorldZoneEdgeRequest(
    Guid FromZoneId,
    Guid ToZoneId,
    double DistanceKm,
    bool IsBidirectional);

public record UpdateWorldZoneEdgeRequest(
    double DistanceKm,
    bool IsBidirectional);

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
    public string? Type { get; set; }
    public int Tier { get; set; }
    public int LevelReq { get; set; }
    public int TotalXp { get; set; }
    public double TotalDistanceKm { get; set; }
    public bool IsStart { get; set; }
}

public class WorldZoneEdgePayload
{
    public string? Id { get; set; }
    public string? FromZoneId { get; set; }
    public string? ToZoneId { get; set; }
    public double DistanceKm { get; set; }
    public bool Bidirectional { get; set; }
}
