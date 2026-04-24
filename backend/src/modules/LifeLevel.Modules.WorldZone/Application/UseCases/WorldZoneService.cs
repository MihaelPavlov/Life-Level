using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Domain.Entities;
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

        // Safety: clients should never set destination directly to a crossroads —
        // they must open the fork sheet and pick a branch. Keep the gate here so
        // API misuse doesn't put the user into an ambiguous state.
        if (destinationZone.Type == WorldZoneType.Crossroads)
            throw new InvalidOperationException("Pick a branch from the crossroads sheet.");

        // Enforce permanent path choice at crossroads. If this zone is a branch,
        // record the choice (first visit) or reject if the user already picked
        // the sibling.
        if (destinationZone.BranchOfId.HasValue)
        {
            var crossroadsId = destinationZone.BranchOfId.Value;
            var existing = await db.Set<UserPathChoice>()
                .FirstOrDefaultAsync(c => c.UserId == userId && c.CrossroadsZoneId == crossroadsId);

            if (existing != null)
            {
                if (existing.ChosenBranchZoneId != destinationZoneId)
                    throw new PathAlreadyChosenException("You already chose a different path at this crossroads.");
                // Same branch as before — proceed normally.
            }
            else
            {
                db.Set<UserPathChoice>().Add(new UserPathChoice
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    CrossroadsZoneId = crossroadsId,
                    ChosenBranchZoneId = destinationZoneId,
                    ChosenAt = DateTime.UtcNow,
                });
            }
        }

        // Multi-hop destination. The user can pick any reachable zone —
        // backend plans the shortest path, sets the final destination as
        // the goal, and uses the first edge along the path as the current
        // active edge. As the user logs distance, `AddDistanceAsync`
        // auto-advances through intermediate edges until arrival.
        var firstEdge = await FindNextEdgeAsync(
            progress.CurrentZoneId, destinationZoneId, userId, CancellationToken.None);
        if (firstEdge == null)
            throw new InvalidOperationException(
                "No route available to that destination. Progress further or pick a different branch.");

        // Preserve edge progress when the user re-taps the same destination
        // (or switches to a target that still starts with the current edge).
        // Only zero out DistanceTraveledOnEdge when the edge actually changes.
        var keepEdgeProgress = progress.CurrentEdgeId == firstEdge.Id;
        progress.DestinationZoneId = destinationZoneId;
        progress.CurrentEdgeId = firstEdge.Id;
        if (!keepEdgeProgress) progress.DistanceTraveledOnEdge = 0;
        progress.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();
    }

    /// BFS from `fromZoneId` to `toZoneId` on the full edge graph, honouring
    /// recorded path choices at crossroads (un-chosen branches are skipped).
    /// Returns the first edge along the shortest path, or null when none
    /// exists. The edges used to compute the traversal may be non-adjacent
    /// to the user's current zone — this is the whole point of the fix.
    private async Task<WorldZoneEdgeEntity?> FindNextEdgeAsync(
        Guid fromZoneId, Guid toZoneId, Guid userId, CancellationToken ct)
    {
        if (fromZoneId == toZoneId) return null;

        var edges = await db.Set<WorldZoneEdgeEntity>().ToListAsync(ct);

        // Zones that are permanently locked for this user because the user
        // chose the sibling branch at the parent crossroads. BFS should
        // never traverse through or into those zones.
        var choices = await db.Set<UserPathChoice>()
            .Where(c => c.UserId == userId)
            .ToListAsync(ct);
        var blockedZoneIds = new HashSet<Guid>();
        if (choices.Count > 0)
        {
            var branchesByCrossroads = await db.Set<WorldZoneEntity>()
                .Where(z => z.BranchOfId != null)
                .Select(z => new { z.Id, CrossroadsId = z.BranchOfId!.Value })
                .ToListAsync(ct);
            foreach (var choice in choices)
            {
                var siblings = branchesByCrossroads
                    .Where(b => b.CrossroadsId == choice.CrossroadsZoneId &&
                                b.Id != choice.ChosenBranchZoneId);
                foreach (var s in siblings) blockedZoneIds.Add(s.Id);
            }
        }

        // Adjacency list. Directional edges → one entry; bidirectional → two.
        var adj = new Dictionary<Guid, List<(Guid next, WorldZoneEdgeEntity edge)>>();
        void AddEdge(Guid a, Guid b, WorldZoneEdgeEntity e)
        {
            if (blockedZoneIds.Contains(a) || blockedZoneIds.Contains(b)) return;
            if (!adj.TryGetValue(a, out var list)) adj[a] = list = new();
            list.Add((b, e));
        }
        foreach (var e in edges)
        {
            AddEdge(e.FromZoneId, e.ToZoneId, e);
            if (e.IsBidirectional) AddEdge(e.ToZoneId, e.FromZoneId, e);
        }

        // Standard BFS. parentEdge[z] = the edge that got us to z.
        var visited = new HashSet<Guid> { fromZoneId };
        var parentEdge = new Dictionary<Guid, (Guid prev, WorldZoneEdgeEntity edge)>();
        var queue = new Queue<Guid>();
        queue.Enqueue(fromZoneId);
        bool found = false;
        while (queue.Count > 0)
        {
            var z = queue.Dequeue();
            if (z == toZoneId) { found = true; break; }
            if (!adj.TryGetValue(z, out var outs)) continue;
            foreach (var (next, edge) in outs)
            {
                if (!visited.Add(next)) continue;
                parentEdge[next] = (z, edge);
                queue.Enqueue(next);
            }
        }
        if (!found) return null;

        // Walk parentEdge backward from destination to source; the last
        // edge we pop is the first step on the path.
        var cursor = toZoneId;
        WorldZoneEdgeEntity? firstEdge = null;
        while (cursor != fromZoneId)
        {
            var (prev, edge) = parentEdge[cursor];
            firstEdge = edge;
            cursor = prev;
        }
        return firstEdge;
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

        // Multi-hop support: a single AddDistance call may carry the user
        // across several edges. Accumulate incoming km, then advance one
        // edge at a time while km remains and the current edge's target
        // isn't the final destination. Each hop unlocks the arrived-at
        // zone and awards XP.
        var edge = await db.Set<WorldZoneEdgeEntity>().FindAsync([progress.CurrentEdgeId], ct)
            ?? throw new InvalidOperationException("Edge not found.");

        var remainingKm = km;
        var discoveredZones = new List<WorldZoneEntity>();

        while (remainingKm > 0 && progress.CurrentEdgeId != null && progress.DestinationZoneId != null)
        {
            var oldDist = progress.DistanceTraveledOnEdge;
            progress.DistanceTraveledOnEdge += remainingKm;
            log.LogInformation(
                "WorldZone.AddDistance APPLY user={UserId} edge={EdgeId} incomingKm={Km} oldKm={OldKm} newKm={NewKm} edgeKm={EdgeKm}",
                userId, progress.CurrentEdgeId, remainingKm, oldDist, progress.DistanceTraveledOnEdge, edge.DistanceKm);

            if (progress.DistanceTraveledOnEdge < edge.DistanceKm)
            {
                // Didn't reach the next zone yet — partial travel, done.
                remainingKm = 0;
                break;
            }

            // Crossed into the edge's target zone. Carry over any excess km
            // to the next hop so a single big workout advances multiple zones.
            var excessKm = progress.DistanceTraveledOnEdge - edge.DistanceKm;
            var arrivedZoneId = edge.FromZoneId == progress.CurrentZoneId
                ? edge.ToZoneId
                : edge.FromZoneId;

            progress.CurrentZoneId = arrivedZoneId;
            progress.DistanceTraveledOnEdge = 0;

            var arrivedRegionId = await db.Set<WorldZoneEntity>()
                .Where(z => z.Id == arrivedZoneId)
                .Select(z => (Guid?)z.RegionId)
                .FirstOrDefaultAsync(ct);
            if (arrivedRegionId != null) progress.CurrentRegionId = arrivedRegionId;

            var alreadyUnlocked = progress.UnlockedZones.Any(u => u.WorldZoneId == arrivedZoneId);
            if (!alreadyUnlocked)
            {
                var unlock = new UserZoneUnlockEntity
                {
                    UserId = userId,
                    WorldZoneId = arrivedZoneId,
                    UserWorldProgressId = progress.Id,
                    UnlockedAt = DateTime.UtcNow,
                };
                db.Set<UserZoneUnlockEntity>().Add(unlock);
                progress.UnlockedZones.Add(unlock);

                var zoneEntity = await db.Set<WorldZoneEntity>().FindAsync([arrivedZoneId], ct);
                if (zoneEntity != null) discoveredZones.Add(zoneEntity);
            }

            if (arrivedZoneId == progress.DestinationZoneId)
            {
                // End of planned journey — clear destination.
                progress.CurrentEdgeId = null;
                progress.DestinationZoneId = null;
                remainingKm = 0;
                break;
            }

            // Plan the next hop toward the final destination.
            var nextEdge = await FindNextEdgeAsync(
                arrivedZoneId, progress.DestinationZoneId!.Value, userId, ct);
            if (nextEdge == null)
            {
                // Path broken mid-journey (e.g. branch locked in the meantime).
                // Park the user at the arrived zone and clear the goal; the
                // excess km is dropped on the floor.
                progress.CurrentEdgeId = null;
                progress.DestinationZoneId = null;
                remainingKm = 0;
                break;
            }
            progress.CurrentEdgeId = nextEdge.Id;
            edge = nextEdge;
            remainingKm = excessKm;
        }

        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        foreach (var discovered in discoveredZones)
        {
            if (discovered.XpReward > 0)
            {
                await characterXp.AwardXpAsync(
                    userId,
                    "ZoneDiscovery",
                    "🗺️",
                    $"Discovered {discovered.Name}",
                    discovered.XpReward);
            }
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
