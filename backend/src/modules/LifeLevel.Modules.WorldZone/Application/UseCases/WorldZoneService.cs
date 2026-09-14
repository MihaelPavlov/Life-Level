using System.Text.Json;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Events;
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
    IEventPublisher events,
    WorldDungeonService? dungeonService = null,
    WorldBossBridgeService? bossBridge = null,
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
                PendingDistanceKm = progress.PendingDistanceKm,
                DestinationZoneId = progress.DestinationZoneId,
                UnlockedZoneIds = unlockedIds.ToList()
            }
        };
    }

    public async Task<Application.DTOs.SetWorldDestinationResult> SetDestinationAsync(Guid userId, Guid destinationZoneId)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive)
            ?? throw new InvalidOperationException("No active world found.");

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        var destinationZone = await db.Set<WorldZoneEntity>().FindAsync(destinationZoneId)
            ?? throw new InvalidOperationException("Zone not found.");

        // Crossroads IS a legal destination now — the mobile client shows
        // the branch-choice sheet only once the user arrives there, so picking
        // a crossroads here means "travel to the fork, then I'll choose".

        // Enforce arrival-at-crossroads before picking a branch. Multi-hop
        // routing is allowed for every other zone type, but branches have to
        // be chosen FROM the parent crossroads so the user sees the
        // "remaining distance" story cleanly.
        if (destinationZone.BranchOfId.HasValue &&
            progress.CurrentZoneId != destinationZone.BranchOfId.Value)
        {
            var crossroadsName = await db.Set<WorldZoneEntity>()
                .Where(z => z.Id == destinationZone.BranchOfId.Value)
                .Select(z => z.Name)
                .FirstOrDefaultAsync() ?? "the crossroads";
            throw new BranchRequiresCrossroadsArrivalException(
                crossroadsName: crossroadsName,
                crossroadsZoneId: destinationZone.BranchOfId.Value);
        }

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

        // Dungeon forfeit: if the user is currently standing on a dungeon
        // zone with an active (or un-entered) run and is moving AWAY from
        // it, the run transitions to Abandoned and every non-Completed
        // floor becomes Forfeited. The count is surfaced in the response
        // so the client can show a "N floors forfeited" snackbar.
        int forfeitedFloors = 0;
        var currentZoneForForfeit = progress.CurrentZoneId;
        if (dungeonService != null && currentZoneForForfeit != destinationZoneId)
        {
            var currentZone = await db.Set<WorldZoneEntity>().FindAsync(currentZoneForForfeit);
            if (currentZone != null && currentZone.Type == WorldZoneType.Dungeon)
            {
                forfeitedFloors = await dungeonService.AbandonAsync(userId, currentZoneForForfeit);
            }
        }

        var pendingKm = progress.PendingDistanceKm;
        if (pendingKm > 0) progress.PendingDistanceKm = 0;
        await db.SaveChangesAsync();

        // Spend banked km immediately once the user picks a destination.
        // AddDistanceAsync handles movement, multi-hop carryover, and any
        // encounter reached while consuming the banked distance.
        ActiveEncounterDto? activeEncounter = null;
        if (pendingKm > 0)
        {
            activeEncounter = await AddDistanceAsync(userId, pendingKm);
        }

        return new Application.DTOs.SetWorldDestinationResult(forfeitedFloors, activeEncounter);
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

    /// Explicit interface implementation — maps the full internal DTO to the shared-kernel port DTO.
    async Task<SharedKernel.DTOs.ActiveEncounterPortDto?> IWorldZoneDistancePort.AddDistanceAsync(
        Guid userId, double km, CancellationToken ct)
    {
        var enc = await AddDistanceAsync(userId, km, ct);
        if (enc == null) return null;
        return new SharedKernel.DTOs.ActiveEncounterPortDto(enc.TemplateId, enc.Type, enc.Name, enc.Emoji);
    }

    public async Task<ActiveEncounterDto?> AddDistanceAsync(Guid userId, double km, CancellationToken ct = default)
    {
        var log = logger ?? NullLogger<WorldZoneService>.Instance;

        if (km <= 0)
        {
            log.LogInformation("WorldZone.AddDistance SKIP user={UserId} incomingKm={Km} reason=non-positive", userId, km);
            return null;
        }

        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive, ct);
        if (activeWorld == null)
        {
            log.LogInformation("WorldZone.AddDistance SKIP user={UserId} incomingKm={Km} reason=no-active-world", userId, km);
            return null;
        }

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id, ct)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        if (progress.CurrentEdgeId == null || progress.DestinationZoneId == null)
        {
            // No destination set — bank the distance so the user doesn't lose
            // it. SetDestinationAsync will drain it onto the new edge.
            progress.PendingDistanceKm += km;
            progress.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
            log.LogInformation("WorldZone.AddDistance BANK user={UserId} incomingKm={Km} pendingKm={PendingKm}",
                userId, km, progress.PendingDistanceKm);
            return null;
        }

        if (progress.ActiveBlockerEncounterId.HasValue &&
            await IsTrailBlockerDefeatedAsync(userId, progress.ActiveBlockerEncounterId.Value, ct))
        {
            if (progress.ActiveTrailEncounterId == progress.ActiveBlockerEncounterId.Value)
            {
                progress.ActiveTrailEncounterId = null;
            }
            progress.ActiveBlockerEncounterId = null;
            progress.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
        }

        // Multi-hop support: a single AddDistance call may carry the user
        // across several edges. Absorb any banked km here so they process
        // together with the incoming workout km — this is when encounters
        // should trigger, not when the destination is first tapped.
        var totalKm = km + progress.PendingDistanceKm;
        progress.PendingDistanceKm = 0;

        var edge = await db.Set<WorldZoneEdgeEntity>().FindAsync([progress.CurrentEdgeId], ct)
            ?? throw new InvalidOperationException("Edge not found.");

        var remainingKm = totalKm;
        var discoveredZones = new List<WorldZoneEntity>();

        while (remainingKm > 0 && progress.CurrentEdgeId != null && progress.DestinationZoneId != null)
        {
            var oldDist = progress.DistanceTraveledOnEdge;
            progress.DistanceTraveledOnEdge += remainingKm;
            log.LogInformation(
                "WorldZone.AddDistance APPLY user={UserId} edge={EdgeId} incomingKm={Km} oldKm={OldKm} newKm={NewKm} edgeKm={EdgeKm}",
                userId, progress.CurrentEdgeId, remainingKm, oldDist, progress.DistanceTraveledOnEdge, edge.DistanceKm);

            // ── Encounter intercept ────────────────────────────────────────
            // A merchant/story encounter must not be passed until the client
            // calls ContinuePendingDistanceAsync. Keep banking any extra km.
            if (progress.ActiveTrailEncounterId.HasValue &&
                progress.ActiveBlockerEncounterId != progress.ActiveTrailEncounterId)
            {
                var activeEncounter = await db.Set<TrailEncounterTemplate>()
                    .FindAsync([progress.ActiveTrailEncounterId.Value], ct);
                if (activeEncounter != null)
                {
                    var (_, aPos) = TrailEncounterHelper.ComputeEncounterSlot(
                        edge.Id, activeEncounter.Id, activeEncounter.SpawnChance,
                        edgeFromZoneId: edge.FromZoneId, edgeToZoneId: edge.ToZoneId,
                        pinnedFromZone: activeEncounter.PinnedFromZoneId, pinnedToZone: activeEncounter.PinnedToZoneId,
                        fixedPosition: activeEncounter.PositionFraction);
                    var encounterKm = aPos * edge.DistanceKm;
                    var encounterExcess = Math.Max(0.0, progress.DistanceTraveledOnEdge - encounterKm);
                    progress.PendingDistanceKm += encounterExcess;
                    progress.DistanceTraveledOnEdge = encounterKm;
                    remainingKm = 0;
                    progress.UpdatedAt = DateTime.UtcNow;
                    await db.SaveChangesAsync(ct);
                    return BuildActiveEncounterDto(activeEncounter);
                }
                progress.ActiveTrailEncounterId = null;
            }

            // If a blocker is already active on this edge, cap movement at
            // the encounter position and refuse to advance further.
            if (progress.ActiveBlockerEncounterId.HasValue)
            {
                var blocker = await db.Set<TrailEncounterTemplate>()
                    .FindAsync([progress.ActiveBlockerEncounterId.Value], ct);
                if (blocker != null)
                {
                    var (_, bPos) = TrailEncounterHelper.ComputeEncounterSlot(
                        edge.Id, blocker.Id, blocker.SpawnChance,
                        edgeFromZoneId: edge.FromZoneId, edgeToZoneId: edge.ToZoneId,
                        pinnedFromZone: blocker.PinnedFromZoneId, pinnedToZone: blocker.PinnedToZoneId,
                        fixedPosition: blocker.PositionFraction);
                    var blockKm = bPos * edge.DistanceKm;
                    var blockerExcess = Math.Max(0.0, progress.DistanceTraveledOnEdge - blockKm);
                    progress.PendingDistanceKm += blockerExcess;
                    progress.DistanceTraveledOnEdge = blockKm;
                    remainingKm = 0;
                    progress.UpdatedAt = DateTime.UtcNow;
                    if (bossBridge != null)
                    {
                        await bossBridge.EnsureTrailBlockerSpawnedAsync(userId, blocker.Id, ct);
                    }
                    await db.SaveChangesAsync(ct);
                    return null;
                }
            }

            // Check for new encounters the player would cross on this hop.
            if (progress.CurrentRegionId.HasValue)
            {
                var regionTemplates = await db.Set<TrailEncounterTemplate>()
                    .Where(t => t.RegionId == progress.CurrentRegionId.Value && t.IsActive)
                    .OrderBy(t => t.Id)
                    .ToListAsync(ct);
                var defeatedBlockerTemplateIds = await GetDefeatedTrailBlockerTemplateIdsAsync(userId, ct);

                var selectedEncounter = TrailEncounterHelper.SelectEncounterForEdge(
                    regionTemplates,
                    edge.Id,
                    edge.FromZoneId,
                    edge.ToZoneId);

                if (selectedEncounter is { } encounter)
                {
                    var template = encounter.Template;
                    var encounterKm = encounter.T * edge.DistanceKm;
                    // Only trigger if we crossed this position on this hop
                    if (!defeatedBlockerTemplateIds.Contains(template.Id) &&
                        oldDist < encounterKm &&
                        progress.DistanceTraveledOnEdge >= encounterKm)
                    {
                        var encounterExcess = Math.Max(0.0, progress.DistanceTraveledOnEdge - encounterKm);
                        progress.PendingDistanceKm += encounterExcess;
                        progress.DistanceTraveledOnEdge = encounterKm;
                        remainingKm = 0;
                        Guid? blockerBossId = null;

                        if (template.Type == "blocker")
                        {
                            progress.ActiveBlockerEncounterId = template.Id;
                            if (bossBridge != null)
                            {
                                blockerBossId = await bossBridge.EnsureTrailBlockerSpawnedAsync(userId, template.Id, ct);
                            }
                        }
                        progress.ActiveTrailEncounterId = template.Id;

                        progress.UpdatedAt = DateTime.UtcNow;
                        await db.SaveChangesAsync(ct);
                        return BuildActiveEncounterDto(template, blockerBossId);
                    }
                }
            }
            // ── End encounter intercept ────────────────────────────────────

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

            // Dungeon forfeit on auto-advance: if we're LEAVING a dungeon
            // zone (sourceZone was a dungeon and it's not the destination),
            // abandon any active run there.
            var leavingZoneId = progress.CurrentZoneId;
            if (dungeonService != null && leavingZoneId != arrivedZoneId)
            {
                var leavingZone = await db.Set<WorldZoneEntity>().FindAsync([leavingZoneId], ct);
                if (leavingZone != null && leavingZone.Type == WorldZoneType.Dungeon)
                {
                    await dungeonService.AbandonAsync(userId, leavingZoneId, ct);
                }
            }

            progress.CurrentZoneId = arrivedZoneId;
            progress.DistanceTraveledOnEdge = 0;

            var arrivedRegionId = await db.Set<WorldZoneEntity>()
                .Where(z => z.Id == arrivedZoneId)
                .Select(z => (Guid?)z.RegionId)
                .FirstOrDefaultAsync(ct);
            if (arrivedRegionId != null) progress.CurrentRegionId = arrivedRegionId;

            var alreadyUnlocked = progress.UnlockedZones.Any(u => u.WorldZoneId == arrivedZoneId);
            WorldZoneEntity? arrivedZoneEntity = null;
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

                arrivedZoneEntity = await db.Set<WorldZoneEntity>().FindAsync([arrivedZoneId], ct);
                if (arrivedZoneEntity != null) discoveredZones.Add(arrivedZoneEntity);
            }

            // Boss-zone arrival hook: lazy-spawn a legacy Boss row so the
            // existing BossScreen / damage pipeline can render the fight.
            // Safe on every hop — the bridge is idempotent. Wrapped in try/catch
            // so a bridge failure never breaks normal travel.
            if (bossBridge != null)
            {
                arrivedZoneEntity ??= await db.Set<WorldZoneEntity>().FindAsync([arrivedZoneId], ct);
                if (arrivedZoneEntity != null &&
                    (arrivedZoneEntity.Type == WorldZoneType.Boss || arrivedZoneEntity.IsBoss))
                {
                    try
                    {
                        await bossBridge.EnsureSpawnedAsync(userId, arrivedZoneId, ct);
                    }
                    catch (Exception bossEx)
                    {
                        log.LogWarning(bossEx,
                            "WorldZone.AddDistance boss-bridge FAILED user={UserId} zoneId={ZoneId}",
                            userId, arrivedZoneId);
                    }
                }
            }

            if (arrivedZoneId == progress.DestinationZoneId)
            {
                // End of planned journey — bank any leftover km the user
                // logged past the destination so it isn't dropped on the floor.
                if (excessKm > 0) progress.PendingDistanceKm += excessKm;
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
                // Park the user at the arrived zone, bank any leftover km, and
                // clear the goal so the user can re-plan.
                if (excessKm > 0) progress.PendingDistanceKm += excessKm;
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

        return null;
    }

    public async Task<ActiveEncounterDto?> ContinuePendingDistanceAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive, ct)
            ?? throw new InvalidOperationException("No active world found.");

        var progress = await db.Set<UserWorldProgressEntity>()
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id, ct)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        var pendingKm = progress.PendingDistanceKm;
        if (pendingKm <= 0 || progress.CurrentEdgeId == null || progress.DestinationZoneId == null)
            return null;

        progress.ActiveTrailEncounterId = null;
        progress.PendingDistanceKm = 0;
        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        return await AddDistanceAsync(userId, pendingKm, ct);
    }

    public async Task<CompleteZoneResult> CompleteZoneAsync(Guid userId, Guid zoneId)
    {
        var log = logger ?? NullLogger<WorldZoneService>.Instance;
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

            await events.PublishAsync(new ZoneCompletedEvent(userId, zoneId), CancellationToken.None);

            if (zone.XpReward > 0)
            {
                xpAwarded = zone.XpReward;
                await db.SaveChangesAsync();
                await characterXp.AwardXpAsync(
                    userId, "ZoneCompletion", zone.Emoji,
                    $"Completed {zone.Name}", zone.XpReward);
            }
        }

        // Boss safety-net spawn. Ensures the legacy Boss row exists even if the
        // user somehow reached this zone without going through AddDistanceAsync
        // (teleport, admin tool, etc.). Idempotent.
        var isBossZone = zone.Type == WorldZoneType.Boss || zone.IsBoss;
        if (isBossZone && bossBridge != null)
        {
            try
            {
                await bossBridge.EnsureSpawnedAsync(userId, zoneId);
            }
            catch (Exception bossEx)
            {
                log.LogWarning(bossEx,
                    "WorldZone.CompleteZone boss-bridge FAILED user={UserId} zoneId={ZoneId}",
                    userId, zoneId);
            }
        }

        // Auto-advance after a region-boss completion: follow an edge from this
        // zone into a different region's entry zone. The mobile client then
        // picks up the advance on its next /api/map/world fetch.
        Guid? nextRegionId = null;
        string? nextRegionName = null;
        string? nextRegionEmoji = null;
        string? nextEntryZoneName = null;

        if (isBossZone)
        {
            var crossRegionEdge = await db.Set<WorldZoneEdgeEntity>()
                .Where(e => e.FromZoneId == zoneId)
                .Join(db.Set<WorldZoneEntity>().Include(z => z.Region),
                      edge => edge.ToZoneId,
                      toZone => toZone.Id,
                      (edge, toZone) => new { edge, toZone })
                .Where(x => x.toZone.RegionId != zone.RegionId
                            && x.toZone.Type == WorldZoneType.Entry)
                .Select(x => x.toZone)
                .FirstOrDefaultAsync();

            if (crossRegionEdge != null)
            {
                progress.CurrentZoneId = crossRegionEdge.Id;
                progress.CurrentRegionId = crossRegionEdge.RegionId;

                var entryUnlocked = progress.UnlockedZones.Any(u => u.WorldZoneId == crossRegionEdge.Id);
                if (!entryUnlocked)
                {
                    db.Set<UserZoneUnlockEntity>().Add(new UserZoneUnlockEntity
                    {
                        UserId = userId,
                        WorldZoneId = crossRegionEdge.Id,
                        UserWorldProgressId = progress.Id,
                        UnlockedAt = DateTime.UtcNow,
                    });
                }

                nextRegionId = crossRegionEdge.RegionId;
                nextRegionName = crossRegionEdge.Region?.Name;
                nextRegionEmoji = crossRegionEdge.Region?.Emoji;
                nextEntryZoneName = crossRegionEdge.Name;
            }
        }

        await db.SaveChangesAsync();

        return new CompleteZoneResult
        {
            ZoneName = zone.Name,
            ZoneEmoji = zone.Emoji,
            XpAwarded = xpAwarded,
            AlreadyCompleted = alreadyUnlocked,
            NextRegionId = nextRegionId,
            NextRegionName = nextRegionName,
            NextRegionEmoji = nextRegionEmoji,
            NextEntryZoneName = nextEntryZoneName,
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

    public async Task ClearBlockerEncounterAsync(Guid userId)
    {
        await ClearBlockerEncounterAsync(userId, null);
    }

    public async Task ClearBlockerEncounterAsync(
        Guid userId,
        Guid? trailEncounterTemplateId,
        bool applyPendingDistance = true,
        CancellationToken ct = default)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive, ct)
            ?? throw new InvalidOperationException("No active world found.");
        var progress = await db.Set<UserWorldProgressEntity>()
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id, ct);
        if (progress == null) return;
        if (trailEncounterTemplateId.HasValue &&
            progress.ActiveBlockerEncounterId != trailEncounterTemplateId.Value)
        {
            return;
        }
        progress.ActiveBlockerEncounterId = null;
        if (!trailEncounterTemplateId.HasValue ||
            progress.ActiveTrailEncounterId == trailEncounterTemplateId.Value)
        {
            progress.ActiveTrailEncounterId = null;
        }
        var pendingKm = progress.PendingDistanceKm;
        if (applyPendingDistance && pendingKm > 0)
        {
            progress.PendingDistanceKm = 0;
        }
        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        if (applyPendingDistance &&
            pendingKm > 0 &&
            progress.CurrentEdgeId.HasValue &&
            progress.DestinationZoneId.HasValue)
        {
            await AddDistanceAsync(userId, pendingKm, ct);
        }
    }

    private async Task<bool> IsTrailBlockerDefeatedAsync(
        Guid userId,
        Guid trailEncounterTemplateId,
        CancellationToken ct)
    {
        return await db.Set<Boss>()
            .Join(
                db.Set<UserBossState>().Where(s => s.UserId == userId),
                boss => boss.Id,
                state => state.BossId,
                (boss, state) => new { boss, state })
            .AnyAsync(x => x.boss.TrailEncounterTemplateId == trailEncounterTemplateId &&
                           x.state.IsDefeated,
                ct);
    }

    private async Task<HashSet<Guid>> GetDefeatedTrailBlockerTemplateIdsAsync(
        Guid userId,
        CancellationToken ct)
    {
        var ids = await db.Set<Boss>()
            .Join(
                db.Set<UserBossState>().Where(s => s.UserId == userId && s.IsDefeated),
                boss => boss.Id,
                state => state.BossId,
                (boss, state) => boss.TrailEncounterTemplateId)
            .Where(id => id.HasValue)
            .Select(id => id!.Value)
            .ToListAsync(ct);

        return ids.ToHashSet();
    }

    private static ActiveEncounterDto BuildActiveEncounterDto(TrailEncounterTemplate template, Guid? blockerBossId = null)
    {
        MerchantEncounterDto? merchant = null;
        BlockerEncounterDto? blocker = null;
        StoryEncounterDto? story = null;

        if (template.ConfigJson != null)
        {
            var config = JsonDocument.Parse(template.ConfigJson).RootElement;
            if (template.Type == "merchant")
            {
                var items = config.TryGetProperty("items", out var itemsEl)
                    ? itemsEl.EnumerateArray().Select(i => new MerchantItemDto(
                        Emoji: i.TryGetProperty("emoji", out var ie) ? ie.GetString() ?? "" : "",
                        Name: i.TryGetProperty("name", out var iname) ? iname.GetString() ?? "" : "",
                        Description: i.TryGetProperty("description", out var idesc) ? idesc.GetString() ?? "" : "",
                        Rarity: i.TryGetProperty("rarity", out var irar) ? irar.GetString() ?? "Common" : "Common",
                        XpCost: i.TryGetProperty("xpCost", out var ixp) ? ixp.GetInt32() : 0)).ToList()
                    : new List<MerchantItemDto>();
                merchant = new MerchantEncounterDto(template.Name, 3600, 0, items);
            }
            else if (template.Type == "blocker")
            {
                var hp = config.TryGetProperty("maxHp", out var hpEl) ? hpEl.GetInt32() : 100;
                var retreatDays = config.TryGetProperty("retreatDays", out var retreatEl) ? retreatEl.GetInt32() : 1;
                var rewards = config.TryGetProperty("rewards", out var rewardsEl)
                    ? rewardsEl.EnumerateArray()
                        .Select(r => r.ValueKind == JsonValueKind.String
                            ? r.GetString() ?? ""
                            : r.TryGetProperty("name", out var rn) ? rn.GetString() ?? "" : r.ToString())
                        .Where(s => s.Length > 0).ToList()
                    : new List<string>();
                blocker = new BlockerEncounterDto(
                    template.Name,
                    "Next Zone",
                    hp,
                    hp,
                    0,
                    Math.Max(1, retreatDays) * 86400,
                    rewards,
                    blockerBossId);
            }
            else if (template.Type == "story")
            {
                var npcName = config.TryGetProperty("npcName", out var nn) ? nn.GetString() ?? template.Name : template.Name;
                var npcTitle = config.TryGetProperty("npcTitle", out var nt) ? nt.GetString() ?? "" : "";
                var portrait = config.TryGetProperty("portrait", out var pp) ? pp.GetString() ?? template.Emoji : template.Emoji;
                var dialogue = config.TryGetProperty("dialogue", out var dd) ? dd.GetString() ?? "" : "";
                story = new StoryEncounterDto(npcName, npcTitle, portrait, dialogue, 0);
            }
        }

        return new ActiveEncounterDto(template.Id, template.Type, template.Name, template.Emoji, merchant, blocker, story);
    }
}
