using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using WorldEntity = LifeLevel.Modules.WorldZone.Domain.Entities.World;
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using WorldZoneEdgeEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZoneEdge;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;
using UserZoneUnlockEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserZoneUnlock;

namespace LifeLevel.Modules.WorldZone.Application.UseCases;

public class WorldZoneService(DbContext db, ICharacterXpPort characterXp, ICharacterLevelReadPort characterLevel, IMapNodeCountPort mapNodeCount, IMapNodeCompletedCountPort mapNodeCompletedCount)
{
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

        var zones = await db.Set<WorldZoneEntity>()
            .Where(z => z.WorldId == activeWorld.Id)
            .ToListAsync();

        var zoneIds = zones.Select(z => z.Id).ToHashSet();

        var nodeCounts = await mapNodeCount.GetNodeCountsByZoneIdsAsync(zoneIds);
        var completedNodeCounts = await mapNodeCompletedCount.GetCompletedNodeCountsByZoneIdsAsync(userId, zoneIds);

        var edges = await db.Set<WorldZoneEdgeEntity>()
            .Where(e => zoneIds.Contains(e.FromZoneId))
            .ToListAsync();

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id);

        if (progress == null)
            progress = await InitializeUserProgressAsync(userId, activeWorld.Id);

        int charLevel = await characterLevel.GetLevelAsync(userId);

        var unlockedIds = progress.UnlockedZones.Select(u => u.WorldZoneId).ToHashSet();

        return new WorldFullResponse
        {
            CharacterLevel = charLevel,
            Zones = zones.Select(z => new WorldZoneDto
            {
                Id = z.Id,
                Name = z.Name,
                Description = z.Description,
                Icon = z.Icon,
                Region = z.Region,
                Tier = z.Tier,
                PositionX = z.PositionX,
                PositionY = z.PositionY,
                LevelRequirement = z.LevelRequirement,
                TotalXp = z.TotalXp,
                TotalDistanceKm = z.TotalDistanceKm,
                IsCrossroads = z.IsCrossroads,
                IsStartZone = z.IsStartZone,
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

        // Crossroads: instant pass-through — no distance required
        if (destinationZone.IsCrossroads)
        {
            progress.CurrentZoneId = destinationZoneId;
            progress.CurrentEdgeId = null;
            progress.DistanceTraveledOnEdge = 0;
            progress.DestinationZoneId = null;
            progress.UpdatedAt = DateTime.UtcNow;

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
                await db.SaveChangesAsync();

                if (destinationZone.TotalXp > 0)
                {
                    await characterXp.AwardXpAsync(
                        userId, "ZoneDiscovery", destinationZone.Icon,
                        $"Passed through {destinationZone.Name}", destinationZone.TotalXp);
                }
            }
            else
            {
                await db.SaveChangesAsync();
            }
            return;
        }

        var edge = await db.Set<WorldZoneEdgeEntity>().FirstOrDefaultAsync(e =>
            (e.FromZoneId == progress.CurrentZoneId && e.ToZoneId == destinationZoneId) ||
            (e.IsBidirectional && e.ToZoneId == progress.CurrentZoneId && e.FromZoneId == destinationZoneId));

        progress.DestinationZoneId = destinationZoneId;
        progress.CurrentEdgeId = edge?.Id;
        progress.DistanceTraveledOnEdge = 0;
        progress.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();
    }

    public async Task AddDistanceAsync(Guid userId, double km)
    {
        var activeWorld = await db.Set<WorldEntity>().FirstOrDefaultAsync(w => w.IsActive)
            ?? throw new InvalidOperationException("No active world found.");

        var progress = await db.Set<UserWorldProgressEntity>()
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        if (progress.CurrentEdgeId == null || progress.DestinationZoneId == null)
            throw new InvalidOperationException("No active destination set. Set a destination first.");

        var edge = await db.Set<WorldZoneEdgeEntity>().FindAsync(progress.CurrentEdgeId)
            ?? throw new InvalidOperationException("Edge not found.");

        progress.DistanceTraveledOnEdge += km;
        WorldZoneEntity? discoveredZone = null;

        if (progress.DistanceTraveledOnEdge >= edge.DistanceKm)
        {
            var destinationZoneId = progress.DestinationZoneId.Value;
            progress.CurrentZoneId = destinationZoneId;
            progress.CurrentEdgeId = null;
            progress.DistanceTraveledOnEdge = 0;
            progress.DestinationZoneId = null;

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

                discoveredZone = await db.Set<WorldZoneEntity>().FindAsync(destinationZoneId);
            }
        }

        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        if (discoveredZone != null && discoveredZone.TotalXp > 0)
        {
            await characterXp.AwardXpAsync(
                userId,
                "ZoneDiscovery",
                "🗺️",
                $"Discovered {discoveredZone.Name}",
                discoveredZone.TotalXp);
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

            if (zone.TotalXp > 0)
            {
                xpAwarded = zone.TotalXp;
                await db.SaveChangesAsync();
                await characterXp.AwardXpAsync(
                    userId, "ZoneCompletion", zone.Icon,
                    $"Completed {zone.Name}", zone.TotalXp);
            }
        }

        await db.SaveChangesAsync();

        return new CompleteZoneResult
        {
            ZoneName = zone.Name,
            ZoneIcon = zone.Icon,
            XpAwarded = xpAwarded,
            AlreadyCompleted = alreadyUnlocked
        };
    }

    private async Task<UserWorldProgressEntity> InitializeUserProgressAsync(Guid userId, Guid worldId)
    {
        var startZone = await db.Set<WorldZoneEntity>()
            .Where(z => z.WorldId == worldId)
            .FirstOrDefaultAsync(z => z.IsStartZone)
            ?? await db.Set<WorldZoneEntity>().Where(z => z.WorldId == worldId).FirstAsync();

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = worldId,
            CurrentZoneId = startZone.Id,
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
