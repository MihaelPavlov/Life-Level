using System.Text.Json;
using LifeLevel.Api.Controllers.Admin;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/admin/map")]
[Authorize(Roles = "Admin")]
public class AdminMapController(AppDbContext db) : ControllerBase
{
    // ─────────────────────────────────────────────────────────────────────────
    // Health (anon)
    // ─────────────────────────────────────────────────────────────────────────

    [HttpGet("health")]
    [AllowAnonymous]
    public IActionResult Health() => Ok(new { status = "ok", timestamp = DateTime.UtcNow });

    // ─────────────────────────────────────────────────────────────────────────
    // Enums
    // ─────────────────────────────────────────────────────────────────────────

    [HttpGet("enums")]
    public IActionResult GetEnums() => Ok(new EnumsDto(
        EnumOptions<WorldZoneType>(),
        EnumOptions<RegionTheme>(),
        EnumOptions<RegionStatus>(),
        EnumOptions<RegionBossStatus>(),
        EnumOptions<ActivityType>(),
        EnumOptions<DungeonFloorTargetKind>()));

    // ─────────────────────────────────────────────────────────────────────────
    // Worlds
    // ─────────────────────────────────────────────────────────────────────────

    [HttpGet("worlds")]
    public async Task<IActionResult> ListWorlds()
    {
        var worlds = await db.Worlds
            .OrderByDescending(w => w.IsActive)
            .ThenBy(w => w.Name)
            .Select(w => new WorldSummaryDto(
                w.Id,
                w.Name,
                w.IsActive,
                w.CreatedAt,
                w.Regions.Count,
                w.Regions.SelectMany(r => r.Zones).Count()))
            .ToListAsync();
        return Ok(worlds);
    }

    [HttpGet("worlds/{id:guid}")]
    public async Task<IActionResult> GetWorld(Guid id)
    {
        var world = await db.Worlds
            .Include(w => w.Regions)
            .ThenInclude(r => r.Zones)
            .FirstOrDefaultAsync(w => w.Id == id);
        if (world is null) return NotFound();

        var regions = world.Regions
            .OrderBy(r => r.ChapterIndex)
            .ThenBy(r => r.Name)
            .Select(r => new RegionSummaryDto(
                r.Id, r.WorldId, r.Name, r.Emoji, r.Theme,
                r.ChapterIndex, r.LevelRequirement, r.Zones.Count))
            .ToList();

        return Ok(new WorldDetailDto(world.Id, world.Name, world.IsActive, world.CreatedAt, regions));
    }

    [HttpPost("worlds")]
    public async Task<IActionResult> CreateWorld([FromBody] CreateWorldRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name)) return BadRequest(new { error = "name is required" });

        if (req.IsActive) await DeactivateOtherWorldsAsync(Guid.Empty);
        var world = new World { Id = Guid.NewGuid(), Name = req.Name.Trim(), IsActive = req.IsActive };
        db.Worlds.Add(world);
        await db.SaveChangesAsync();
        return Ok(new WorldSummaryDto(world.Id, world.Name, world.IsActive, world.CreatedAt, 0, 0));
    }

    [HttpPut("worlds/{id:guid}")]
    public async Task<IActionResult> UpdateWorld(Guid id, [FromBody] UpdateWorldRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name)) return BadRequest(new { error = "name is required" });

        var world = await db.Worlds.FirstOrDefaultAsync(w => w.Id == id);
        if (world is null) return NotFound();

        world.Name = req.Name.Trim();
        world.IsActive = req.IsActive;
        if (req.IsActive) await DeactivateOtherWorldsAsync(world.Id);
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("worlds/{id:guid}")]
    public async Task<IActionResult> DeleteWorld(Guid id)
    {
        var world = await db.Worlds.FirstOrDefaultAsync(w => w.Id == id);
        if (world is null) return NotFound();

        var hasRegions = await db.Regions.AnyAsync(r => r.WorldId == id);
        if (hasRegions) return BadRequest(new { error = "world has regions; delete them first" });

        var hasProgress = await db.UserWorldProgresses.AnyAsync(p => p.WorldId == id);
        if (hasProgress) return BadRequest(new { error = "world has user progress; cannot delete" });

        db.Worlds.Remove(world);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Regions
    // ─────────────────────────────────────────────────────────────────────────

    [HttpGet("worlds/{worldId:guid}/regions")]
    public async Task<IActionResult> ListRegions(Guid worldId)
    {
        var exists = await db.Worlds.AnyAsync(w => w.Id == worldId);
        if (!exists) return NotFound();

        var regions = await db.Regions
            .Where(r => r.WorldId == worldId)
            .OrderBy(r => r.ChapterIndex)
            .ThenBy(r => r.Name)
            .Select(r => new RegionSummaryDto(
                r.Id, r.WorldId, r.Name, r.Emoji, r.Theme,
                r.ChapterIndex, r.LevelRequirement, r.Zones.Count))
            .ToListAsync();
        return Ok(regions);
    }

    [HttpGet("regions/{id:guid}")]
    public async Task<IActionResult> GetRegion(Guid id)
    {
        var region = await db.Regions
            .Include(r => r.Zones)
            .FirstOrDefaultAsync(r => r.Id == id);
        if (region is null) return NotFound();

        var zoneIds = region.Zones.Select(z => z.Id).ToList();
        var floorCounts = await db.WorldZoneDungeonFloors
            .Where(f => zoneIds.Contains(f.WorldZoneId))
            .GroupBy(f => f.WorldZoneId)
            .Select(g => new { WorldZoneId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.WorldZoneId, x => x.Count);

        var zones = region.Zones
            .OrderBy(z => z.Tier)
            .ThenBy(z => z.Name)
            .Select(z => MapZoneSummary(z, floorCounts.GetValueOrDefault(z.Id, 0)))
            .ToList();

        var edges = await db.WorldZoneEdges
            .Where(e => zoneIds.Contains(e.FromZoneId) && zoneIds.Contains(e.ToZoneId))
            .Select(e => new EdgeDto(e.Id, e.FromZoneId, e.ToZoneId, e.DistanceKm, e.IsBidirectional))
            .ToListAsync();

        var pins = ParsePins(region.PinsJson);

        return Ok(new RegionDetailDto(
            region.Id, region.WorldId, region.Name, region.Emoji, region.Theme,
            region.ChapterIndex, region.LevelRequirement, region.Lore,
            region.BossName, region.BossStatus, region.DefaultStatus,
            pins, zones, edges));
    }

    [HttpPost("worlds/{worldId:guid}/regions")]
    public async Task<IActionResult> CreateRegion(Guid worldId, [FromBody] CreateRegionRequest req)
    {
        var world = await db.Worlds.FirstOrDefaultAsync(w => w.Id == worldId);
        if (world is null) return NotFound(new { error = "world not found" });
        if (string.IsNullOrWhiteSpace(req.Name)) return BadRequest(new { error = "name is required" });

        var region = new Region
        {
            Id = Guid.NewGuid(),
            WorldId = worldId,
            Name = req.Name.Trim(),
            Emoji = (req.Emoji ?? "").Trim(),
            Theme = req.Theme,
            ChapterIndex = req.ChapterIndex,
            LevelRequirement = Math.Max(1, req.LevelRequirement),
            Lore = req.Lore ?? "",
            BossName = req.BossName ?? "",
            BossStatus = req.BossStatus,
            DefaultStatus = req.DefaultStatus,
            PinsJson = SerializePins(req.Pins),
        };
        db.Regions.Add(region);
        await db.SaveChangesAsync();

        return Ok(new RegionSummaryDto(
            region.Id, region.WorldId, region.Name, region.Emoji, region.Theme,
            region.ChapterIndex, region.LevelRequirement, 0));
    }

    [HttpPut("regions/{id:guid}")]
    public async Task<IActionResult> UpdateRegion(Guid id, [FromBody] UpdateRegionRequest req)
    {
        var region = await db.Regions.FirstOrDefaultAsync(r => r.Id == id);
        if (region is null) return NotFound();
        if (string.IsNullOrWhiteSpace(req.Name)) return BadRequest(new { error = "name is required" });

        region.Name = req.Name.Trim();
        region.Emoji = (req.Emoji ?? "").Trim();
        region.Theme = req.Theme;
        region.ChapterIndex = req.ChapterIndex;
        region.LevelRequirement = Math.Max(1, req.LevelRequirement);
        region.Lore = req.Lore ?? "";
        region.BossName = req.BossName ?? "";
        region.BossStatus = req.BossStatus;
        region.DefaultStatus = req.DefaultStatus;
        region.PinsJson = SerializePins(req.Pins);

        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("regions/{id:guid}")]
    public async Task<IActionResult> DeleteRegion(Guid id)
    {
        var region = await db.Regions.FirstOrDefaultAsync(r => r.Id == id);
        if (region is null) return NotFound();

        var hasZones = await db.WorldZones.AnyAsync(z => z.RegionId == id);
        if (hasZones) return BadRequest(new { error = "region has zones; delete them first" });

        db.Regions.Remove(region);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Zones
    // ─────────────────────────────────────────────────────────────────────────

    [HttpGet("regions/{regionId:guid}/zones")]
    public async Task<IActionResult> ListZones(Guid regionId)
    {
        var exists = await db.Regions.AnyAsync(r => r.Id == regionId);
        if (!exists) return NotFound();

        var zones = await db.WorldZones
            .Where(z => z.RegionId == regionId)
            .OrderBy(z => z.Tier)
            .ThenBy(z => z.Name)
            .ToListAsync();

        var zoneIds = zones.Select(z => z.Id).ToList();
        var floorCounts = await db.WorldZoneDungeonFloors
            .Where(f => zoneIds.Contains(f.WorldZoneId))
            .GroupBy(f => f.WorldZoneId)
            .Select(g => new { WorldZoneId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.WorldZoneId, x => x.Count);

        var result = zones.Select(z => MapZoneSummary(z, floorCounts.GetValueOrDefault(z.Id, 0))).ToList();
        return Ok(result);
    }

    [HttpGet("zones/{id:guid}")]
    public async Task<IActionResult> GetZone(Guid id)
    {
        var zone = await db.WorldZones.FirstOrDefaultAsync(z => z.Id == id);
        if (zone is null) return NotFound();

        var floors = await db.WorldZoneDungeonFloors
            .Where(f => f.WorldZoneId == id)
            .OrderBy(f => f.Ordinal)
            .Select(f => new FloorDto(f.Id, f.WorldZoneId, f.Ordinal, f.ActivityType, f.TargetKind, f.TargetValue, f.Name, f.Emoji))
            .ToListAsync();

        return Ok(MapZoneDetail(zone, floors));
    }

    [HttpPost("regions/{regionId:guid}/zones")]
    public async Task<IActionResult> CreateZone(Guid regionId, [FromBody] CreateZoneRequest req)
    {
        var region = await db.Regions.FirstOrDefaultAsync(r => r.Id == regionId);
        if (region is null) return NotFound(new { error = "region not found" });
        if (string.IsNullOrWhiteSpace(req.Name)) return BadRequest(new { error = "name is required" });

        if (req.IsStartZone)
        {
            var existingStart = await db.WorldZones.AnyAsync(z => z.RegionId == regionId && z.IsStartZone);
            if (existingStart) return BadRequest(new { error = "region already has a start zone" });
        }

        if (req.BranchOfId is Guid branchId)
        {
            var branchValid = await db.WorldZones.AnyAsync(z => z.Id == branchId && z.RegionId == regionId && z.Type == WorldZoneType.Crossroads);
            if (!branchValid) return BadRequest(new { error = "branchOfId must reference a Crossroads zone in the same region" });
        }

        var zone = new WorldZoneEntity
        {
            Id = Guid.NewGuid(),
            RegionId = regionId,
            Name = req.Name.Trim(),
            Description = req.Description,
            Emoji = (req.Emoji ?? "").Trim(),
            Type = req.Type,
            Tier = req.Tier,
            LevelRequirement = Math.Max(1, req.LevelRequirement),
            XpReward = Math.Max(0, req.XpReward),
            DistanceKm = Math.Max(0, req.DistanceKm),
            IsStartZone = req.IsStartZone,
            IsBoss = req.Type == WorldZoneType.Boss,
            BranchOfId = req.BranchOfId,
            LoreTotal = req.LoreTotal,
            NodesTotal = req.NodesTotal,
        };
        ApplyTypeSpecificFields(zone, req.Type, req.ChestRewardXp, req.ChestRewardDescription,
            req.DungeonBonusXp, req.BossTimerDays, req.BossSuppressExpiry);

        db.WorldZones.Add(zone);
        await db.SaveChangesAsync();

        return Ok(MapZoneSummary(zone, 0));
    }

    [HttpPut("zones/{id:guid}")]
    public async Task<IActionResult> UpdateZone(Guid id, [FromBody] UpdateZoneRequest req)
    {
        var zone = await db.WorldZones.FirstOrDefaultAsync(z => z.Id == id);
        if (zone is null) return NotFound();
        if (string.IsNullOrWhiteSpace(req.Name)) return BadRequest(new { error = "name is required" });

        if (req.IsStartZone && !zone.IsStartZone)
        {
            var existingStart = await db.WorldZones.AnyAsync(z => z.RegionId == zone.RegionId && z.IsStartZone && z.Id != id);
            if (existingStart) return BadRequest(new { error = "region already has a start zone" });
        }

        if (req.BranchOfId is Guid branchId)
        {
            if (branchId == id) return BadRequest(new { error = "zone cannot branch from itself" });
            var branchValid = await db.WorldZones.AnyAsync(z => z.Id == branchId && z.RegionId == zone.RegionId && z.Type == WorldZoneType.Crossroads);
            if (!branchValid) return BadRequest(new { error = "branchOfId must reference a Crossroads zone in the same region" });
        }

        zone.Name = req.Name.Trim();
        zone.Description = req.Description;
        zone.Emoji = (req.Emoji ?? "").Trim();
        zone.Type = req.Type;
        zone.Tier = req.Tier;
        zone.LevelRequirement = Math.Max(1, req.LevelRequirement);
        zone.XpReward = Math.Max(0, req.XpReward);
        zone.DistanceKm = Math.Max(0, req.DistanceKm);
        zone.IsStartZone = req.IsStartZone;
        zone.IsBoss = req.Type == WorldZoneType.Boss;
        zone.BranchOfId = req.BranchOfId;
        zone.LoreTotal = req.LoreTotal;
        zone.NodesTotal = req.NodesTotal;
        ApplyTypeSpecificFields(zone, req.Type, req.ChestRewardXp, req.ChestRewardDescription,
            req.DungeonBonusXp, req.BossTimerDays, req.BossSuppressExpiry);

        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("zones/{id:guid}")]
    public async Task<IActionResult> DeleteZone(Guid id)
    {
        var zone = await db.WorldZones.FirstOrDefaultAsync(z => z.Id == id);
        if (zone is null) return NotFound();

        var inUse = await db.UserWorldProgresses.AnyAsync(p =>
            p.CurrentZoneId == id || p.DestinationZoneId == id);
        if (inUse) return BadRequest(new { error = "zone is referenced by user progress; cannot delete" });

        var unlocked = await db.UserZoneUnlocks.AnyAsync(u => u.WorldZoneId == id);
        if (unlocked) return BadRequest(new { error = "zone has user unlocks; cannot delete" });

        var floors = await db.WorldZoneDungeonFloors.Where(f => f.WorldZoneId == id).ToListAsync();
        db.WorldZoneDungeonFloors.RemoveRange(floors);
        var edges = await db.WorldZoneEdges.Where(e => e.FromZoneId == id || e.ToZoneId == id).ToListAsync();
        db.WorldZoneEdges.RemoveRange(edges);

        db.WorldZones.Remove(zone);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Edges
    // ─────────────────────────────────────────────────────────────────────────

    [HttpGet("regions/{regionId:guid}/edges")]
    public async Task<IActionResult> ListEdges(Guid regionId)
    {
        var exists = await db.Regions.AnyAsync(r => r.Id == regionId);
        if (!exists) return NotFound();

        var zoneIds = await db.WorldZones.Where(z => z.RegionId == regionId).Select(z => z.Id).ToListAsync();

        var edges = await db.WorldZoneEdges
            .Where(e => zoneIds.Contains(e.FromZoneId) && zoneIds.Contains(e.ToZoneId))
            .Select(e => new EdgeDto(e.Id, e.FromZoneId, e.ToZoneId, e.DistanceKm, e.IsBidirectional))
            .ToListAsync();
        return Ok(edges);
    }

    [HttpPost("edges")]
    public async Task<IActionResult> CreateEdge([FromBody] CreateEdgeRequest req)
    {
        if (req.FromZoneId == req.ToZoneId) return BadRequest(new { error = "from and to must differ" });

        var zones = await db.WorldZones
            .Where(z => z.Id == req.FromZoneId || z.Id == req.ToZoneId)
            .Select(z => new { z.Id, z.RegionId })
            .ToListAsync();
        if (zones.Count != 2) return BadRequest(new { error = "both zones must exist" });
        if (zones[0].RegionId != zones[1].RegionId)
            return BadRequest(new { error = "both zones must belong to the same region" });

        var duplicate = await db.WorldZoneEdges.AnyAsync(e =>
            (e.FromZoneId == req.FromZoneId && e.ToZoneId == req.ToZoneId) ||
            (e.FromZoneId == req.ToZoneId && e.ToZoneId == req.FromZoneId));
        if (duplicate) return BadRequest(new { error = "an edge between these zones already exists" });

        var edge = new WorldZoneEdge
        {
            Id = Guid.NewGuid(),
            FromZoneId = req.FromZoneId,
            ToZoneId = req.ToZoneId,
            DistanceKm = Math.Max(0, req.DistanceKm),
            IsBidirectional = req.IsBidirectional,
        };
        db.WorldZoneEdges.Add(edge);
        await db.SaveChangesAsync();

        return Ok(new EdgeDto(edge.Id, edge.FromZoneId, edge.ToZoneId, edge.DistanceKm, edge.IsBidirectional));
    }

    [HttpPut("edges/{id:guid}")]
    public async Task<IActionResult> UpdateEdge(Guid id, [FromBody] UpdateEdgeRequest req)
    {
        var edge = await db.WorldZoneEdges.FirstOrDefaultAsync(e => e.Id == id);
        if (edge is null) return NotFound();

        edge.DistanceKm = Math.Max(0, req.DistanceKm);
        edge.IsBidirectional = req.IsBidirectional;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("edges/{id:guid}")]
    public async Task<IActionResult> DeleteEdge(Guid id)
    {
        var edge = await db.WorldZoneEdges.FirstOrDefaultAsync(e => e.Id == id);
        if (edge is null) return NotFound();

        // Null out any user progress that is currently traveling along this edge.
        var travelers = await db.UserWorldProgresses.Where(p => p.CurrentEdgeId == id).ToListAsync();
        foreach (var p in travelers)
        {
            p.CurrentEdgeId = null;
            p.DistanceTraveledOnEdge = 0;
            p.DestinationZoneId = null;
        }

        db.WorldZoneEdges.Remove(edge);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Dungeon floors
    // ─────────────────────────────────────────────────────────────────────────

    [HttpGet("zones/{zoneId:guid}/floors")]
    public async Task<IActionResult> ListFloors(Guid zoneId)
    {
        var exists = await db.WorldZones.AnyAsync(z => z.Id == zoneId);
        if (!exists) return NotFound();

        var floors = await db.WorldZoneDungeonFloors
            .Where(f => f.WorldZoneId == zoneId)
            .OrderBy(f => f.Ordinal)
            .Select(f => new FloorDto(f.Id, f.WorldZoneId, f.Ordinal, f.ActivityType, f.TargetKind, f.TargetValue, f.Name, f.Emoji))
            .ToListAsync();
        return Ok(floors);
    }

    [HttpPost("zones/{zoneId:guid}/floors")]
    public async Task<IActionResult> CreateFloor(Guid zoneId, [FromBody] CreateFloorRequest req)
    {
        var zone = await db.WorldZones.FirstOrDefaultAsync(z => z.Id == zoneId);
        if (zone is null) return NotFound(new { error = "zone not found" });
        if (zone.Type != WorldZoneType.Dungeon)
            return BadRequest(new { error = "floors can only be added to Dungeon zones" });
        if (req.Ordinal < 1) return BadRequest(new { error = "ordinal must be >= 1" });

        var duplicate = await db.WorldZoneDungeonFloors.AnyAsync(f => f.WorldZoneId == zoneId && f.Ordinal == req.Ordinal);
        if (duplicate) return BadRequest(new { error = $"floor ordinal {req.Ordinal} already exists" });

        var floor = new WorldZoneDungeonFloor
        {
            Id = Guid.NewGuid(),
            WorldZoneId = zoneId,
            Ordinal = req.Ordinal,
            ActivityType = req.ActivityType,
            TargetKind = req.TargetKind,
            TargetValue = Math.Max(0, req.TargetValue),
            Name = req.Name ?? "",
            Emoji = req.Emoji ?? "",
        };
        db.WorldZoneDungeonFloors.Add(floor);
        await db.SaveChangesAsync();

        return Ok(new FloorDto(floor.Id, floor.WorldZoneId, floor.Ordinal, floor.ActivityType, floor.TargetKind, floor.TargetValue, floor.Name, floor.Emoji));
    }

    [HttpPut("floors/{id:guid}")]
    public async Task<IActionResult> UpdateFloor(Guid id, [FromBody] UpdateFloorRequest req)
    {
        var floor = await db.WorldZoneDungeonFloors.FirstOrDefaultAsync(f => f.Id == id);
        if (floor is null) return NotFound();
        if (req.Ordinal < 1) return BadRequest(new { error = "ordinal must be >= 1" });

        if (req.Ordinal != floor.Ordinal)
        {
            var duplicate = await db.WorldZoneDungeonFloors.AnyAsync(f =>
                f.WorldZoneId == floor.WorldZoneId && f.Ordinal == req.Ordinal && f.Id != id);
            if (duplicate) return BadRequest(new { error = $"floor ordinal {req.Ordinal} already exists" });
        }

        floor.Ordinal = req.Ordinal;
        floor.ActivityType = req.ActivityType;
        floor.TargetKind = req.TargetKind;
        floor.TargetValue = Math.Max(0, req.TargetValue);
        floor.Name = req.Name ?? "";
        floor.Emoji = req.Emoji ?? "";
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("floors/{id:guid}")]
    public async Task<IActionResult> DeleteFloor(Guid id)
    {
        var floor = await db.WorldZoneDungeonFloors.FirstOrDefaultAsync(f => f.Id == id);
        if (floor is null) return NotFound();

        db.WorldZoneDungeonFloors.Remove(floor);
        await db.SaveChangesAsync();
        return NoContent();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static ZoneSummaryDto MapZoneSummary(WorldZoneEntity z, int floorCount) => new(
        z.Id, z.RegionId, z.Name, z.Emoji, z.Type, z.Tier, z.LevelRequirement,
        z.XpReward, z.DistanceKm, z.IsStartZone, z.IsBoss, z.BranchOfId,
        z.ChestRewardXp, z.DungeonBonusXp, z.BossTimerDays, z.BossSuppressExpiry, floorCount);

    private static ZoneDetailDto MapZoneDetail(WorldZoneEntity z, IReadOnlyList<FloorDto> floors) => new(
        z.Id, z.RegionId, z.Name, z.Description, z.Emoji, z.Type, z.Tier, z.LevelRequirement,
        z.XpReward, z.DistanceKm, z.IsStartZone, z.IsBoss, z.BranchOfId,
        z.LoreTotal, z.LoreCollected, z.NodesTotal, z.NodesCompleted,
        z.ChestRewardXp, z.ChestRewardDescription, z.DungeonBonusXp,
        z.BossTimerDays, z.BossSuppressExpiry, floors);

    private static void ApplyTypeSpecificFields(
        WorldZoneEntity zone,
        WorldZoneType type,
        int? chestRewardXp,
        string? chestRewardDescription,
        int? dungeonBonusXp,
        int? bossTimerDays,
        bool? bossSuppressExpiry)
    {
        // Chest fields only persist for Chest zones; other types reset to null.
        zone.ChestRewardXp           = type == WorldZoneType.Chest   ? chestRewardXp           : null;
        zone.ChestRewardDescription  = type == WorldZoneType.Chest   ? chestRewardDescription  : null;
        zone.DungeonBonusXp          = type == WorldZoneType.Dungeon ? dungeonBonusXp          : null;
        zone.BossTimerDays           = type == WorldZoneType.Boss    ? bossTimerDays           : null;
        zone.BossSuppressExpiry      = type == WorldZoneType.Boss    ? bossSuppressExpiry      : null;
    }

    private async Task DeactivateOtherWorldsAsync(Guid keepId)
    {
        var others = await db.Worlds.Where(w => w.Id != keepId && w.IsActive).ToListAsync();
        foreach (var w in others) w.IsActive = false;
    }

    private static IReadOnlyList<EnumOption> EnumOptions<T>() where T : struct, Enum =>
        Enum.GetValues<T>()
            .Select(v => new EnumOption(Convert.ToInt32(v), v.ToString()))
            .ToList();

    private static IReadOnlyList<RegionPinDto> ParsePins(string json)
    {
        if (string.IsNullOrWhiteSpace(json)) return Array.Empty<RegionPinDto>();
        try
        {
            var list = JsonSerializer.Deserialize<List<RegionPinDto>>(json);
            return list ?? new List<RegionPinDto>();
        }
        catch
        {
            return Array.Empty<RegionPinDto>();
        }
    }

    private static string SerializePins(IReadOnlyList<RegionPinDto>? pins) =>
        JsonSerializer.Serialize(pins ?? new List<RegionPinDto>());
}
