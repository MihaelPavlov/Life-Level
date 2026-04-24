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
    IUserReadPort userRead,
    IBossDefeatReadPort bossDefeatRead)
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

        // First-time hub open: brand new users don't yet have a UserWorldProgress
        // row, so every zone comes back locked and the region detail shows
        // nothing tappable. Seed them at the first-region entry zone right here
        // so the very first `/api/map/world` call returns a live state. Mirrors
        // the pattern already used by WorldZoneService.GetFullWorldAsync.
        if (progress == null)
        {
            progress = await EnsureUserWorldProgressAsync(userId, activeWorld.Id, zones, ct);
        }

        var unlocked = progress.UnlockedZones.Select(u => u.WorldZoneId).ToHashSet();
        var currentRegionId = progress.CurrentRegionId;

        // Which of this user's world-zone bosses have an IsDefeated
        // UserBossState. Drives the "completed" region status — arriving at a
        // boss zone marks it unlocked, but only defeating the boss completes
        // the region.
        var defeatedBossZoneIds = await bossDefeatRead.GetDefeatedWorldZoneIdsAsync(userId, ct);

        var summaries = regions
            .Select(r => BuildRegionSummary(r, zones, unlocked, defeatedBossZoneIds, currentRegionId, level))
            .ToList();

        ActiveJourneyDto? journey = BuildActiveJourney(progress);

        return new WorldMapDto(new WorldUserDto(level, name), journey, summaries);
    }

    /// Seeds a fresh UserWorldProgress at the lowest-tier entry zone of the
    /// lowest-chapter region. Idempotent — the caller already checked that
    /// no row exists, and we re-fetch afterwards with the same eager-load
    /// shape so downstream code sees the populated navigation properties.
    private async Task<UserWorldProgressEntity> EnsureUserWorldProgressAsync(
        Guid userId,
        Guid worldId,
        IReadOnlyList<WorldZoneEntity> zones,
        CancellationToken ct)
    {
        // Pick the starter zone: prefer IsStartZone, else the lowest-chapter
        // Entry-typed zone.
        var startZone = zones
            .OrderBy(z => z.IsStartZone ? 0 : 1)
            .ThenBy(z => z.Type == WorldZoneType.Entry ? 0 : 1)
            .ThenBy(z => z.Tier)
            .First();

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = worldId,
            CurrentZoneId = startZone.Id,
            CurrentRegionId = startZone.RegionId,
            DistanceTraveledOnEdge = 0,
            UpdatedAt = DateTime.UtcNow,
        };

        db.Set<UserWorldProgressEntity>().Add(progress);
        db.Set<UserZoneUnlock>().Add(new UserZoneUnlock
        {
            UserId = userId,
            WorldZoneId = startZone.Id,
            UserWorldProgressId = progress.Id,
            UnlockedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync(ct);

        return (await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .Include(p => p.CurrentEdge)
            .Include(p => p.DestinationZone).ThenInclude(z => z!.Region)
            .FirstAsync(p => p.Id == progress.Id, ct));
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

        // Pre-load chest open state for this region's chest zones so each
        // ZoneNodeDto can carry the ChestIsOpened flag without N+1 queries.
        var chestZoneIds = zones
            .Where(z => z.Type == WorldZoneType.Chest)
            .Select(z => z.Id)
            .ToHashSet();
        HashSet<Guid> openedChestZoneIds;
        if (chestZoneIds.Count == 0)
        {
            openedChestZoneIds = new();
        }
        else
        {
            openedChestZoneIds = (await db.Set<UserWorldChestState>()
                .Where(s => s.UserId == userId && chestZoneIds.Contains(s.WorldZoneId))
                .Select(s => s.WorldZoneId)
                .ToListAsync(ct))
                .ToHashSet();
        }

        // Pre-load dungeon state + floor counts for this region's dungeon zones.
        var dungeonZoneIds = zones
            .Where(z => z.Type == WorldZoneType.Dungeon)
            .Select(z => z.Id)
            .ToHashSet();
        Dictionary<Guid, UserWorldDungeonState> dungeonRunByZone;
        Dictionary<Guid, (int total, int completed, int forfeited)> dungeonFloorCountsByZone;
        if (dungeonZoneIds.Count == 0)
        {
            dungeonRunByZone = new();
            dungeonFloorCountsByZone = new();
        }
        else
        {
            dungeonRunByZone = await db.Set<UserWorldDungeonState>()
                .Where(s => s.UserId == userId && dungeonZoneIds.Contains(s.WorldZoneId))
                .ToDictionaryAsync(s => s.WorldZoneId, ct);

            var allFloors = await db.Set<WorldZoneDungeonFloor>()
                .Where(f => dungeonZoneIds.Contains(f.WorldZoneId))
                .ToListAsync(ct);
            var floorIds = allFloors.Select(f => f.Id).ToList();
            var floorStates = await db.Set<UserWorldDungeonFloorState>()
                .Where(s => s.UserId == userId && floorIds.Contains(s.FloorId))
                .ToDictionaryAsync(s => s.FloorId, ct);

            dungeonFloorCountsByZone = allFloors
                .GroupBy(f => f.WorldZoneId)
                .ToDictionary(g => g.Key, g =>
                {
                    int total = g.Count();
                    int completed = g.Count(f =>
                        floorStates.TryGetValue(f.Id, out var st) &&
                        st.Status == DungeonFloorStatus.Completed);
                    int forfeited = g.Count(f =>
                        floorStates.TryGetValue(f.Id, out var st) &&
                        st.Status == DungeonFloorStatus.Forfeited);
                    return (total, completed, forfeited);
                });
        }

        // Load this user's committed path choices for any crossroads in this
        // region. Branches for a crossroads with a recorded choice show the
        // chosen branch normally; the sibling force-locks.
        var crossroadsIds = zones
            .Where(z => z.Type == WorldZoneType.Crossroads)
            .Select(z => z.Id)
            .ToHashSet();
        Dictionary<Guid, Guid> chosenByCrossroads;
        if (crossroadsIds.Count == 0)
        {
            chosenByCrossroads = new();
        }
        else
        {
            chosenByCrossroads = await db.Set<UserPathChoice>()
                .Where(c => c.UserId == userId && crossroadsIds.Contains(c.CrossroadsZoneId))
                .ToDictionaryAsync(c => c.CrossroadsZoneId, c => c.ChosenBranchZoneId, ct);
        }

        // "Available" = level met AND at least one edge connects from an unlocked
        // zone to this one. Treat edges as bidirectional when flagged.
        var adjacencyToUnlocked = new HashSet<Guid>();
        foreach (var e in edges)
        {
            if (unlocked.Contains(e.FromZoneId)) adjacencyToUnlocked.Add(e.ToZoneId);
            if (e.IsBidirectional && unlocked.Contains(e.ToZoneId)) adjacencyToUnlocked.Add(e.FromZoneId);
        }

        var nodes = zones
            .Select(z => BuildZoneNode(
                z, progress, unlocked, adjacencyToUnlocked, level, chosenByCrossroads,
                openedChestZoneIds, dungeonRunByZone, dungeonFloorCountsByZone))
            .ToList();

        var edgeDtos = edges.Select(e => new ZoneEdgeDto(e.FromZoneId, e.ToZoneId)).ToList();

        var pathChoiceDtos = chosenByCrossroads
            .Select(kv => new PathChoiceDto(kv.Key, kv.Value))
            .ToList();

        var defeatedBossZoneIds = await bossDefeatRead.GetDefeatedWorldZoneIdsAsync(userId, ct);
        var summary = BuildRegionSummary(region, zones, unlocked, defeatedBossZoneIds, progress?.CurrentRegionId, level);

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
            Edges: edgeDtos,
            PathChoices: pathChoiceDtos);
    }

    // ────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ────────────────────────────────────────────────────────────────────────

    private static RegionSummaryDto BuildRegionSummary(
        Region region,
        IReadOnlyList<WorldZoneEntity> allZones,
        HashSet<Guid> unlocked,
        HashSet<Guid> defeatedBossZoneIds,
        Guid? currentRegionId,
        int userLevel)
    {
        var regionZones = allZones.Where(z => z.RegionId == region.Id).ToList();
        var total = regionZones.Count;
        var completedZones = regionZones.Where(z => unlocked.Contains(z.Id)).ToList();
        var xpEarned = completedZones.Sum(z => z.XpReward);

        var bossZone = regionZones.FirstOrDefault(z => z.IsBoss || z.Type == WorldZoneType.Boss);
        // "Defeated" requires a defeated UserBossState — unlocked alone only
        // means the user arrived at the zone, not that they won the fight.
        var bossDefeated = bossZone != null && defeatedBossZoneIds.Contains(bossZone.Id);

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
        else if (bossDefeated)
            // Beating the region's boss completes the region regardless of
            // how many branch zones the user left unvisited. Branches are
            // mutually exclusive so `completedZones.Count == total` would
            // never fire for regions with a crossroads.
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
        int userLevel,
        IReadOnlyDictionary<Guid, Guid> chosenByCrossroads,
        HashSet<Guid> openedChestZoneIds,
        IReadOnlyDictionary<Guid, UserWorldDungeonState> dungeonRunByZone,
        IReadOnlyDictionary<Guid, (int total, int completed, int forfeited)> dungeonFloorCountsByZone)
    {
        string ComputeDefaultStatus()
        {
            if (progress?.CurrentZoneId == z.Id) return "active";
            if (progress?.DestinationZoneId == z.Id) return "next";
            if (unlocked.Contains(z.Id)) return "completed";
            if (userLevel >= z.LevelRequirement && adjacencyToUnlocked.Contains(z.Id)) return "available";
            return "locked";
        }

        string status;
        if (z.BranchOfId.HasValue)
        {
            // Branch zone. Status depends on whether the user has already
            // committed to a path at the parent crossroads.
            if (chosenByCrossroads.TryGetValue(z.BranchOfId.Value, out var chosenBranchId))
            {
                if (chosenBranchId == z.Id)
                {
                    // Chosen branch — normal lifecycle rules apply.
                    status = ComputeDefaultStatus();
                }
                else
                {
                    // Sibling was picked — permanently locked for this user.
                    status = "locked";
                }
            }
            else
            {
                // No choice yet. Both branches are "available" as long as the
                // crossroads itself is reachable and the user meets the level.
                bool crossroadsUnlocked = unlocked.Contains(z.BranchOfId.Value);
                bool crossroadsReachable = crossroadsUnlocked || adjacencyToUnlocked.Contains(z.BranchOfId.Value);
                if (progress?.CurrentZoneId == z.Id)
                    status = "active";
                else if (progress?.DestinationZoneId == z.Id)
                    status = "next";
                else if (unlocked.Contains(z.Id))
                    status = "completed";
                else if (crossroadsReachable && userLevel >= z.LevelRequirement)
                    status = "available";
                else
                    status = "locked";
            }
        }
        else
        {
            status = ComputeDefaultStatus();
        }

        bool isCrossroads = z.Type == WorldZoneType.Crossroads;
        bool isChest = z.Type == WorldZoneType.Chest;
        bool isDungeon = z.Type == WorldZoneType.Dungeon;

        // Chest fields — only populate for chest-typed zones.
        int? chestRewardXp = isChest ? z.ChestRewardXp : null;
        bool? chestIsOpened = isChest ? openedChestZoneIds.Contains(z.Id) : null;

        // Dungeon fields — only populate for dungeon-typed zones.
        int? dungeonFloorsTotal = null;
        int? dungeonFloorsCompleted = null;
        int? dungeonFloorsForfeited = null;
        string? dungeonStatus = null;
        if (isDungeon)
        {
            if (dungeonFloorCountsByZone.TryGetValue(z.Id, out var counts))
            {
                dungeonFloorsTotal = counts.total;
                dungeonFloorsCompleted = counts.completed;
                dungeonFloorsForfeited = counts.forfeited;
            }
            else
            {
                dungeonFloorsTotal = 0;
                dungeonFloorsCompleted = 0;
                dungeonFloorsForfeited = 0;
            }

            dungeonStatus = dungeonRunByZone.TryGetValue(z.Id, out var runState)
                ? runState.Status switch
                {
                    DungeonRunStatus.NotEntered => "notEntered",
                    DungeonRunStatus.InProgress => "inProgress",
                    DungeonRunStatus.Completed => "completed",
                    DungeonRunStatus.Abandoned => "abandoned",
                    _ => "notEntered",
                }
                : "notEntered";
        }

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
            LoreTotal: z.LoreTotal,
            BranchOf: z.BranchOfId,
            IsChest: isChest,
            ChestRewardXp: chestRewardXp,
            ChestIsOpened: chestIsOpened,
            IsDungeon: isDungeon,
            DungeonFloorsTotal: dungeonFloorsTotal,
            DungeonFloorsCompleted: dungeonFloorsCompleted,
            DungeonFloorsForfeited: dungeonFloorsForfeited,
            DungeonStatus: dungeonStatus);
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
