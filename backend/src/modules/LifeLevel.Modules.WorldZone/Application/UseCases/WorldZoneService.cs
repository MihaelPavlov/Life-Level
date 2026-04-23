using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;

using WorldEntity = LifeLevel.Modules.WorldZone.Domain.Entities.World;
using RegionEntity = LifeLevel.Modules.WorldZone.Domain.Entities.Region;
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using WorldZoneEdgeEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZoneEdge;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;
using UserZoneUnlockEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserZoneUnlock;

namespace LifeLevel.Modules.WorldZone.Application.UseCases;

public class WorldZoneService(
    DbContext db,
    ICharacterXpPort characterXp,
    ICharacterLevelReadPort characterLevel,
    IMapNodeCountPort mapNodeCount,
    IMapNodeCompletedCountPort mapNodeCompletedCount,
    ILogger<WorldZoneService>? logger = null)
    : IWorldZoneDistancePort
{
    /// <summary>
    /// Legacy endpoint kept working for the mobile client during the migration
    /// from the old painter-based map to the chapter-based map. New clients
    /// should call <c>/api/map/world</c> + <c>/api/map/region/{id}</c> via
    /// <see cref="MapReadService"/>.
    /// </summary>
    public async Task<WorldFullResponse> GetFullWorldAsync(Guid userId)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive);

        if (activeWorld == null)
        {
            return new WorldFullResponse
            {
                CharacterLevel = 0,
                Zones = [],
                Edges = [],
                UserProgress = new UserWorldProgressDto { UnlockedZoneIds = [] }
            };
        }

        var regionIds = await db.Set<RegionEntity>()
            .Where(r => r.WorldId == activeWorld.Id)
            .Select(r => r.Id)
            .ToListAsync();

        var zones = await db.Set<WorldZoneEntity>()
            .Include(z => z.Region)
            .Where(z => regionIds.Contains(z.RegionId))
            .ToListAsync();

        var zoneIds = zones.Select(z => z.Id).ToHashSet();

        var nodeCounts = await mapNodeCount.GetNodeCountsByZoneIdsAsync(zoneIds);
        var completedNodeCounts = await mapNodeCompletedCount.GetCompletedNodeCountsByZoneIdsAsync(userId, zoneIds);

        var edges = await db.Set<WorldZoneEdgeEntity>()
            .Where(e => zoneIds.Contains(e.FromZoneId))
            .ToListAsync();

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .Include(p => p.CurrentZone).ThenInclude(z => z.Region)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id);

        if (progress == null)
            progress = await InitializeUserProgressAsync(userId, activeWorld.Id);

        int charLevel = await characterLevel.GetLevelAsync(userId);

        var unlockedIds = progress.UnlockedZones.Select(u => u.WorldZoneId).ToHashSet();

        return new WorldFullResponse
        {
            CharacterLevel = charLevel,
            CurrentRegionId = progress.CurrentRegionId ?? progress.CurrentZone?.RegionId,
            Zones = zones.Select(z => new WorldZoneDto
            {
                Id = z.Id,
                Name = z.Name,
                Description = z.Description,
                Emoji = z.Emoji,
                RegionId = z.RegionId,
                Region = z.Region?.Name ?? string.Empty,
                Tier = z.Tier,
                LevelRequirement = z.LevelRequirement,
                XpReward = z.XpReward,
                DistanceKm = z.DistanceKm,
                IsStartZone = z.IsStartZone,
                IsBoss = z.IsBoss,
                Type = z.Type.ToString().ToLowerInvariant(),
                NodeCount = nodeCounts.GetValueOrDefault(z.Id, 0),
                CompletedNodeCount = completedNodeCounts.GetValueOrDefault(z.Id, 0),
                UserState = new ZoneUserStateDto
                {
                    IsUnlocked = unlockedIds.Contains(z.Id),
                    IsLevelMet = charLevel >= z.LevelRequirement,
                    IsCurrentZone = progress.CurrentZoneId == z.Id,
                    IsDestination = progress.DestinationZoneId == z.Id
                }
            }).ToList(),
            Edges = edges.Select(e => new WorldZoneEdgeDto
            {
                Id = e.Id,
                FromZoneId = e.FromZoneId,
                ToZoneId = e.ToZoneId,
                DistanceKm = e.DistanceKm,
                IsBidirectional = e.IsBidirectional
            }).ToList(),
            UserProgress = new UserWorldProgressDto
            {
                CurrentZoneId = progress.CurrentZoneId,
                CurrentEdgeId = progress.CurrentEdgeId,
                DistanceTraveledOnEdge = progress.DistanceTraveledOnEdge,
                DestinationZoneId = progress.DestinationZoneId,
                UnlockedZoneIds = unlockedIds.ToList()
            }
        };
    }

    public async Task SetDestinationAsync(Guid userId, Guid destinationZoneId)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive)
            ?? throw new InvalidOperationException("No active world found.");

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        var destinationZone = await db.Set<WorldZoneEntity>().FindAsync(destinationZoneId)
            ?? throw new InvalidOperationException("Zone not found.");

        var isAdjacent = await db.Set<WorldZoneEdgeEntity>().AnyAsync(e =>
            (e.FromZoneId == progress.CurrentZoneId && e.ToZoneId == destinationZoneId) ||
            (e.IsBidirectional && e.ToZoneId == progress.CurrentZoneId && e.FromZoneId == destinationZoneId));

        if (!isAdjacent)
            throw new InvalidOperationException("Destination zone is not adjacent to your current zone.");

        var edge = await db.Set<WorldZoneEdgeEntity>().FirstOrDefaultAsync(e =>
            (e.FromZoneId == progress.CurrentZoneId && e.ToZoneId == destinationZoneId) ||
            (e.IsBidirectional && e.ToZoneId == progress.CurrentZoneId && e.FromZoneId == destinationZoneId));

        progress.DestinationZoneId = destinationZoneId;
        progress.CurrentEdgeId = edge?.Id;
        progress.DistanceTraveledOnEdge = 0;
        progress.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();
    }

    public async Task AddDistanceAsync(Guid userId, double km, CancellationToken ct = default)
    {
        var log = logger ?? NullLogger<WorldZoneService>.Instance;

        if (km <= 0)
        {
            log.LogInformation("WorldZone.AddDistance SKIP user={UserId} incomingKm={Km} reason=non-positive", userId, km);
            return;
        }

        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive, ct);
        if (activeWorld == null)
        {
            log.LogInformation("WorldZone.AddDistance SKIP user={UserId} incomingKm={Km} reason=no-active-world", userId, km);
            return;
        }

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id, ct)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        if (progress.CurrentEdgeId == null || progress.DestinationZoneId == null)
        {
            log.LogInformation("WorldZone.AddDistance SKIP user={UserId} incomingKm={Km} reason=no-destination currentEdgeId={EdgeId} destinationZoneId={DestId}",
                userId, km, progress.CurrentEdgeId, progress.DestinationZoneId);
            return;
        }

        var edge = await db.Set<WorldZoneEdgeEntity>().FindAsync([progress.CurrentEdgeId], ct)
            ?? throw new InvalidOperationException("Edge not found.");

        var oldDist = progress.DistanceTraveledOnEdge;
        progress.DistanceTraveledOnEdge += km;
        log.LogInformation(
            "WorldZone.AddDistance APPLY user={UserId} edge={EdgeId} incomingKm={Km} oldKm={OldKm} newKm={NewKm} edgeKm={EdgeKm}",
            userId, progress.CurrentEdgeId, km, oldDist, progress.DistanceTraveledOnEdge, edge.DistanceKm);
        WorldZoneEntity? discoveredZone = null;

        if (progress.DistanceTraveledOnEdge >= edge.DistanceKm)
        {
            var destinationZoneId = progress.DestinationZoneId.Value;
            progress.CurrentZoneId = destinationZoneId;
            progress.CurrentEdgeId = null;
            progress.DistanceTraveledOnEdge = 0;
            progress.DestinationZoneId = null;

            // Snapshot the region of the new current zone so the map screen
            // can show the "Active" region pill without a join.
            var destZoneRegionId = await db.Set<WorldZoneEntity>()
                .Where(z => z.Id == destinationZoneId)
                .Select(z => (Guid?)z.RegionId)
                .FirstOrDefaultAsync(ct);
            if (destZoneRegionId != null) progress.CurrentRegionId = destZoneRegionId;

            var alreadyUnlocked = progress.UnlockedZones.Any(u => u.WorldZoneId == destinationZoneId);
            if (!alreadyUnlocked)
            {
                db.Set<UserZoneUnlockEntity>().Add(new UserZoneUnlockEntity
                {
                    UserId = userId,
                    WorldZoneId = destinationZoneId,
                    UserWorldProgressId = progress.Id,
                    UnlockedAt = DateTime.UtcNow
                });

                discoveredZone = await db.Set<WorldZoneEntity>().FindAsync([destinationZoneId], ct);
            }
        }

        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        if (discoveredZone != null && discoveredZone.XpReward > 0)
        {
            await characterXp.AwardXpAsync(
                userId,
                "ZoneDiscovery",
                "🗺️",
                $"Discovered {discoveredZone.Name}",
                discoveredZone.XpReward);
        }
    }

    public async Task<CompleteZoneResult> CompleteZoneAsync(Guid userId, Guid zoneId)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive)
            ?? throw new InvalidOperationException("No active world found.");

        var zone = await db.Set<WorldZoneEntity>().FindAsync(zoneId)
            ?? throw new InvalidOperationException("Zone not found.");

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        progress.CurrentZoneId = zoneId;
        progress.CurrentRegionId = zone.RegionId;
        progress.DestinationZoneId = null;
        progress.CurrentEdgeId = null;
        progress.DistanceTraveledOnEdge = 0;
        progress.UpdatedAt = DateTime.UtcNow;

        var alreadyUnlocked = progress.UnlockedZones.Any(u => u.WorldZoneId == zoneId);
        int xpAwarded = 0;

        if (!alreadyUnlocked)
        {
            db.Set<UserZoneUnlockEntity>().Add(new UserZoneUnlockEntity
            {
                UserId = userId,
                WorldZoneId = zoneId,
                UserWorldProgressId = progress.Id,
                UnlockedAt = DateTime.UtcNow
            });

            if (zone.XpReward > 0)
            {
                xpAwarded = zone.XpReward;
                await db.SaveChangesAsync();
                await characterXp.AwardXpAsync(
                    userId, "ZoneCompletion", zone.Emoji,
                    $"Completed {zone.Name}", zone.XpReward);
            }
        }

        await db.SaveChangesAsync();

        return new CompleteZoneResult
        {
            ZoneName = zone.Name,
            ZoneEmoji = zone.Emoji,
            XpAwarded = xpAwarded,
            AlreadyCompleted = alreadyUnlocked
        };
    }

    /// <summary>
    /// Teleport the user into a region's entry zone (the zone with
    /// <see cref="WorldZoneType.Entry"/>, falling back to IsStartZone or lowest
    /// Tier). Cross-region switch requires <paramref name="force"/>=true.
    /// </summary>
    public async Task EnterRegionAsync(Guid userId, Guid regionId, bool force = false, CancellationToken ct = default)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive, ct)
            ?? throw new InvalidOperationException("No active world found.");

        var region = await db.Set<RegionEntity>()
            .FirstOrDefaultAsync(r => r.Id == regionId && r.WorldId == activeWorld.Id, ct)
            ?? throw new InvalidOperationException("Region not found.");

        int charLevel = await characterLevel.GetLevelAsync(userId, ct);
        if (charLevel < region.LevelRequirement)
            throw new RegionLockedException(region.Name, region.LevelRequirement);

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .Include(p => p.CurrentZone).ThenInclude(z => z.Region)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id, ct)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        if (!force
            && progress.CurrentZone != null
            && progress.CurrentZone.RegionId != regionId)
        {
            var currentRegionName = progress.CurrentZone.Region?.Name
                ?? (await db.Set<RegionEntity>().FindAsync([progress.CurrentZone.RegionId], ct))?.Name
                ?? "current region";

            throw new CrossRegionSwitchRequiresConfirmationException(currentRegionName, region.Name);
        }

        // Entry zone: prefer Type=Entry, then IsStartZone, then lowest Tier.
        var entryZone = await db.Set<WorldZoneEntity>()
            .Where(z => z.RegionId == regionId)
            .OrderBy(z => z.Type == WorldZoneType.Entry ? 0 : 1)
            .ThenBy(z => z.IsStartZone ? 0 : 1)
            .ThenBy(z => z.Tier)
            .ThenBy(z => z.Id)
            .FirstOrDefaultAsync(ct)
            ?? throw new InvalidOperationException("Region has no zones.");

        progress.DestinationZoneId = null;
        progress.CurrentEdgeId = null;
        progress.DistanceTraveledOnEdge = 0;
        progress.CurrentZoneId = entryZone.Id;
        progress.CurrentRegionId = regionId;
        progress.UpdatedAt = DateTime.UtcNow;

        var alreadyUnlocked = progress.UnlockedZones.Any(u => u.WorldZoneId == entryZone.Id);
        if (!alreadyUnlocked)
        {
            db.Set<UserZoneUnlockEntity>().Add(new UserZoneUnlockEntity
            {
                UserId = userId,
                WorldZoneId = entryZone.Id,
                UserWorldProgressId = progress.Id,
                UnlockedAt = DateTime.UtcNow
            });
        }

        await db.SaveChangesAsync(ct);
    }

    private async Task<UserWorldProgressEntity> InitializeUserProgressAsync(Guid userId, Guid worldId)
    {
        // Find the first regi's entry zone: prefer IsStartZone, fall back to
        // the lowest-tier Entry zone in the first region.
        var startZone = await db.Set<WorldZoneEntity>()
            .Include(z => z.Region)
            .Where(z => z.Region.WorldId == worldId)
            .OrderBy(z => z.IsStartZone ? 0 : 1)
            .ThenBy(z => z.Type == WorldZoneType.Entry ? 0 : 1)
            .ThenBy(z => z.Region.ChapterIndex)
            .ThenBy(z => z.Tier)
            .FirstAsync();

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = worldId,
            CurrentZoneId = startZone.Id,
            CurrentRegionId = startZone.RegionId,
            DistanceTraveledOnEdge = 0,
            UpdatedAt = DateTime.UtcNow
        };

        db.Set<UserWorldProgressEntity>().Add(progress);

        db.Set<UserZoneUnlockEntity>().Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = startZone.Id,
            UserWorldProgressId = progress.Id,
            UnlockedAt = DateTime.UtcNow
        });

        await db.SaveChangesAsync();
        return progress;
    }
}
