using System.Text.Json;
using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using WorldEntity = LifeLevel.Modules.WorldZone.Domain.Entities.World;
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using WorldZoneEdgeEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZoneEdge;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;

namespace LifeLevel.Modules.WorldZone.Application.UseCases;

/// <summary>
/// Read-side service for the v3 World Map. Builds the two DTOs that feed the
/// mobile map tab: a light-weight list of region hero cards (/api/map/world)
/// and a per-region detail payload with nodes + edges (/api/map/region/{id}).
///
/// Writes still flow through <see cref="WorldZoneService"/>.
/// </summary>
public class MapReadService(
    DbContext db,
    ICharacterLevelReadPort characterLevel,
    IUserReadPort userRead)
{
    private static readonly JsonSerializerOptions JsonOpts = new() { PropertyNameCaseInsensitive = true };

    public async Task<WorldMapDto> GetWorldMapAsync(Guid userId, CancellationToken ct = default)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive, ct);
        int level = await characterLevel.GetLevelAsync(userId, ct);
        string name = await userRead.GetUsernameAsync(userId, ct) ?? "Explorer";

        if (activeWorld == null)
            return new WorldMapDto(new WorldUserDto(level, name), null, Array.Empty<RegionSummaryDto>());

        var regions = await db.Set<Region>()
            .Where(r => r.WorldId == activeWorld.Id)
            .OrderBy(r => r.ChapterIndex)
            .ToListAsync(ct);

        var regionIds = regions.Select(r => r.Id).ToHashSet();

        var zones = await db.Set<WorldZoneEntity>()
            .Where(z => regionIds.Contains(z.RegionId))
            .ToListAsync(ct);

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .Include(p => p.CurrentEdge)
            .Include(p => p.DestinationZone).ThenInclude(z => z!.Region)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id, ct);

        var unlocked = progress?.UnlockedZones.Select(u => u.WorldZoneId).ToHashSet() ?? [];
        var currentRegionId = progress?.CurrentRegionId;

        var summaries = regions
            .Select(r => BuildRegionSummary(r, zones, unlocked, currentRegionId, level))
            .ToList();

        ActiveJourneyDto? journey = BuildActiveJourney(progress);

        return new WorldMapDto(new WorldUserDto(level, name), journey, summaries);
    }

    public async Task<RegionDetailDto?> GetRegionDetailAsync(Guid userId, Guid regionId, CancellationToken ct = default)
    {
        var region = await db.Set<Region>().FirstOrDefaultAsync(r => r.Id == regionId, ct);
        if (region == null) return null;

        int level = await characterLevel.GetLevelAsync(userId, ct);

        var zones = await db.Set<WorldZoneEntity>()
            .Where(z => z.RegionId == regionId)
            .OrderBy(z => z.Tier)
            .ThenBy(z => z.Name)
            .ToListAsync(ct);

        var zoneIds = zones.Select(z => z.Id).ToHashSet();

        var edges = await db.Set<WorldZoneEdgeEntity>()
            .Where(e => zoneIds.Contains(e.FromZoneId) && zoneIds.Contains(e.ToZoneId))
            .ToListAsync(ct);

        var activeWorldId = region.WorldId;
        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorldId, ct);

        var unlocked = progress?.UnlockedZones.Select(u => u.WorldZoneId).ToHashSet() ?? [];

        // "Available" = level met AND at least one edge connects from an unlocked
        // zone to this one. Treat edges as bidirectional when flagged.
        var adjacencyToUnlocked = new HashSet<Guid>();
        foreach (var e in edges)
        {
            if (unlocked.Contains(e.FromZoneId)) adjacencyToUnlocked.Add(e.ToZoneId);
            if (e.IsBidirectional && unlocked.Contains(e.ToZoneId)) adjacencyToUnlocked.Add(e.FromZoneId);
        }

        var nodes = zones
            .Select(z => BuildZoneNode(z, progress, unlocked, adjacencyToUnlocked, level))
            .ToList();

        var edgeDtos = edges.Select(e => new ZoneEdgeDto(e.FromZoneId, e.ToZoneId)).ToList();

        var summary = BuildRegionSummary(region, zones, unlocked, progress?.CurrentRegionId, level);

        return new RegionDetailDto(
            Id: summary.Id,
            Name: summary.Name,
            Emoji: summary.Emoji,
            Theme: summary.Theme,
            Lore: summary.Lore,
            ChapterIndex: summary.ChapterIndex,
            Status: summary.Status,
            LevelRequirement: summary.LevelRequirement,
            CompletedZones: summary.CompletedZones,
            TotalZones: summary.TotalZones,
            TotalXpEarned: summary.TotalXpEarned,
            ZonesUntilBoss: summary.ZonesUntilBoss,
            BossName: summary.BossName,
            BossStatus: summary.BossStatus,
            Pins: summary.Pins,
            Nodes: nodes,
            Edges: edgeDtos);
    }

    // ────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ────────────────────────────────────────────────────────────────────────

    private static RegionSummaryDto BuildRegionSummary(
        Region region,
        IReadOnlyList<WorldZoneEntity> allZones,
        HashSet<Guid> unlocked,
        Guid? currentRegionId,
        int userLevel)
    {
        var regionZones = allZones.Where(z => z.RegionId == region.Id).ToList();
        var total = regionZones.Count;
        var completedZones = regionZones.Where(z => unlocked.Contains(z.Id)).ToList();
        var xpEarned = completedZones.Sum(z => z.XpReward);

        var bossZone = regionZones.FirstOrDefault(z => z.IsBoss || z.Type == WorldZoneType.Boss);
        var bossDefeated = bossZone != null && unlocked.Contains(bossZone.Id);

        // Zones until boss: tier delta from highest-unlocked non-boss zone to boss.
        // Null when no boss, already defeated, or user hasn't started the region.
        int? zonesUntilBoss = null;
        if (bossZone != null && !bossDefeated)
        {
            var unlockedTiersInRegion = regionZones
                .Where(z => unlocked.Contains(z.Id) && !z.IsBoss)
                .Select(z => z.Tier)
                .DefaultIfEmpty(0)
                .Max();
            zonesUntilBoss = Math.Max(1, bossZone.Tier - unlockedTiersInRegion);
        }

        string status;
        if (userLevel < region.LevelRequirement)
            status = "locked";
        else if (bossDefeated && completedZones.Count == total)
            status = "completed";
        else if (currentRegionId == region.Id)
            status = "active";
        else if (completedZones.Count > 0)
            status = "active";
        else
            status = "active"; // unlocked but untouched — still selectable

        string bossStatus = bossDefeated
            ? "defeated"
            : (userLevel >= region.LevelRequirement ? "available" : "locked");

        var pins = DeserializePins(region.PinsJson);

        return new RegionSummaryDto(
            Id: region.Id,
            Name: region.Name,
            Emoji: region.Emoji,
            Theme: region.Theme.ToString().ToLowerInvariant(),
            Lore: region.Lore,
            ChapterIndex: region.ChapterIndex,
            Status: status,
            LevelRequirement: region.LevelRequirement,
            CompletedZones: completedZones.Count,
            TotalZones: total,
            TotalXpEarned: xpEarned,
            ZonesUntilBoss: zonesUntilBoss,
            BossName: region.BossName,
            BossStatus: bossStatus,
            Pins: pins);
    }

    private static ZoneNodeDto BuildZoneNode(
        WorldZoneEntity z,
        UserWorldProgressEntity? progress,
        HashSet<Guid> unlocked,
        HashSet<Guid> adjacencyToUnlocked,
        int userLevel)
    {
        string status;
        if (progress?.CurrentZoneId == z.Id)
            status = "active";
        else if (progress?.DestinationZoneId == z.Id)
            status = "next";
        else if (unlocked.Contains(z.Id))
            status = "completed";
        else if (userLevel >= z.LevelRequirement && adjacencyToUnlocked.Contains(z.Id))
            status = "available";
        else
            status = "locked";

        bool isCrossroads = z.Type == WorldZoneType.Crossroads;

        return new ZoneNodeDto(
            Id: z.Id,
            Name: z.Name,
            Emoji: z.Emoji,
            Tier: z.Tier,
            Status: status,
            IsCrossroads: isCrossroads,
            IsBoss: z.IsBoss || z.Type == WorldZoneType.Boss,
            Description: z.Description ?? string.Empty,
            LevelRequirement: z.LevelRequirement,
            DistanceKm: z.DistanceKm,
            XpReward: z.XpReward,
            NodesCompleted: z.NodesCompleted,
            NodesTotal: z.NodesTotal,
            LoreCollected: z.LoreCollected,
            LoreTotal: z.LoreTotal);
    }

    private static ActiveJourneyDto? BuildActiveJourney(UserWorldProgressEntity? progress)
    {
        if (progress == null) return null;
        if (progress.CurrentEdgeId == null || progress.DestinationZone == null) return null;

        // Load the edge out-of-band to read the total distance — progress.CurrentEdge
        // is included via eager-load in caller.
        var destZone = progress.DestinationZone;
        var regionName = destZone.Region?.Name ?? string.Empty;

        // DistanceTotalKm comes from the edge. If the eager include didn't
        // populate CurrentEdge we fall back to the zone's own DistanceKm which
        // is the canonical "entry cost" for that zone.
        double totalKm = progress.CurrentEdge?.DistanceKm ?? destZone.DistanceKm;

        return new ActiveJourneyDto(
            DestinationZoneName: destZone.Name,
            DestinationZoneEmoji: destZone.Emoji,
            RegionName: regionName,
            DistanceTravelledKm: progress.DistanceTraveledOnEdge,
            DistanceTotalKm: totalKm,
            ArrivalXpReward: destZone.XpReward,
            ArrivalBonusLabel: null);
    }

    private static IReadOnlyList<RegionPinDto> DeserializePins(string json)
    {
        if (string.IsNullOrWhiteSpace(json) || json == "[]") return [];
        try
        {
            var raw = JsonSerializer.Deserialize<List<RegionPin>>(json, JsonOpts);
            if (raw == null) return [];
            return raw.Select(p => new RegionPinDto(p.Label, p.Value)).ToList();
        }
        catch (JsonException)
        {
            return [];
        }
    }
}
