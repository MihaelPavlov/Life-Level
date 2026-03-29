using LifeLevel.Api.Application.DTOs.Map;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class WorldZoneService(AppDbContext db, CharacterService characterService)
{
    public async Task<WorldFullResponse> GetFullWorldAsync(Guid userId)
    {
        var activeWorld = await db.Worlds.FirstOrDefaultAsync(w => w.IsActive);

        if (activeWorld == null)
        {
            var lvl = await db.Characters
                .Where(c => c.UserId == userId)
                .Select(c => c.Level)
                .FirstOrDefaultAsync();
            return new WorldFullResponse
            {
                CharacterLevel = lvl,
                Zones = [],
                Edges = [],
                UserProgress = new UserWorldProgressDto { UnlockedZoneIds = [] }
            };
        }

        var zones = await db.WorldZones
            .Where(z => z.WorldId == activeWorld.Id)
            .Include(z => z.Nodes)
            .ToListAsync();

        var zoneIds = zones.Select(z => z.Id).ToHashSet();

        var edges = await db.WorldZoneEdges
            .Where(e => zoneIds.Contains(e.FromZoneId))
            .ToListAsync();

        var progress = await db.UserWorldProgresses
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id);

        if (progress == null)
            progress = await InitializeUserProgressAsync(userId, activeWorld.Id);

        var characterLevel = await db.Characters
            .Where(c => c.UserId == userId)
            .Select(c => c.Level)
            .FirstOrDefaultAsync();

        var unlockedIds = progress.UnlockedZones.Select(u => u.WorldZoneId).ToHashSet();

        return new WorldFullResponse
        {
            CharacterLevel = characterLevel,
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
                NodeCount = z.Nodes.Count,
                UserState = new ZoneUserStateDto
                {
                    IsUnlocked = unlockedIds.Contains(z.Id),
                    IsLevelMet = characterLevel >= z.LevelRequirement,
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
        var activeWorld = await db.Worlds.FirstOrDefaultAsync(w => w.IsActive)
            ?? throw new InvalidOperationException("No active world found.");

        var progress = await db.UserWorldProgresses
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        var destinationZone = await db.WorldZones.FindAsync(destinationZoneId)
            ?? throw new InvalidOperationException("Zone not found.");

        var isAdjacent = await db.WorldZoneEdges.AnyAsync(e =>
            (e.FromZoneId == progress.CurrentZoneId && e.ToZoneId == destinationZoneId) ||
            (e.IsBidirectional && e.ToZoneId == progress.CurrentZoneId && e.FromZoneId == destinationZoneId));

        if (!isAdjacent)
            throw new InvalidOperationException("Destination zone is not adjacent to your current zone.");

        var edge = await db.WorldZoneEdges.FirstOrDefaultAsync(e =>
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
        var activeWorld = await db.Worlds.FirstOrDefaultAsync(w => w.IsActive)
            ?? throw new InvalidOperationException("No active world found.");

        var progress = await db.UserWorldProgresses
            .Include(p => p.UnlockedZones)
            .FirstOrDefaultAsync(p => p.UserId == userId && p.WorldId == activeWorld.Id)
            ?? await InitializeUserProgressAsync(userId, activeWorld.Id);

        if (progress.CurrentEdgeId == null || progress.DestinationZoneId == null)
            throw new InvalidOperationException("No active destination set. Set a destination first.");

        var edge = await db.WorldZoneEdges.FindAsync(progress.CurrentEdgeId)
            ?? throw new InvalidOperationException("Edge not found.");

        progress.DistanceTraveledOnEdge += km;
        WorldZone? discoveredZone = null;
        Character? character = null;

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
                db.UserZoneUnlocks.Add(new UserZoneUnlock
                {
                    UserId = userId,
                    WorldZoneId = destinationZoneId,
                    UserWorldProgressId = progress.Id,
                    UnlockedAt = DateTime.UtcNow
                });

                discoveredZone = await db.WorldZones.FindAsync(destinationZoneId);
                character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
                if (discoveredZone != null && character != null && discoveredZone.TotalXp > 0)
                {
                    character.Xp += discoveredZone.TotalXp;
                    character.UpdatedAt = DateTime.UtcNow;
                }
            }
        }

        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();

        if (discoveredZone != null && character != null && discoveredZone.TotalXp > 0)
        {
            await characterService.RecordXpAsync(
                character,
                "ZoneDiscovery",
                "🗺️",
                $"Discovered {discoveredZone.Name}",
                discoveredZone.TotalXp);
        }
    }

    public async Task<CompleteZoneResult> CompleteZoneAsync(Guid userId, Guid zoneId)
    {
        var activeWorld = await db.Worlds.FirstOrDefaultAsync(w => w.IsActive)
            ?? throw new InvalidOperationException("No active world found.");

        var zone = await db.WorldZones.FindAsync(zoneId)
            ?? throw new InvalidOperationException("Zone not found.");

        var progress = await db.UserWorldProgresses
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
            db.UserZoneUnlocks.Add(new UserZoneUnlock
            {
                UserId = userId,
                WorldZoneId = zoneId,
                UserWorldProgressId = progress.Id,
                UnlockedAt = DateTime.UtcNow
            });

            var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId);
            if (character != null && zone.TotalXp > 0)
            {
                character.Xp += zone.TotalXp;
                character.UpdatedAt = DateTime.UtcNow;
                xpAwarded = zone.TotalXp;
                await db.SaveChangesAsync();
                await characterService.RecordXpAsync(
                    character, "ZoneCompletion", zone.Icon,
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

    private async Task<UserWorldProgress> InitializeUserProgressAsync(Guid userId, Guid worldId)
    {
        var startZone = await db.WorldZones
            .Where(z => z.WorldId == worldId)
            .FirstOrDefaultAsync(z => z.IsStartZone)
            ?? await db.WorldZones.Where(z => z.WorldId == worldId).FirstAsync();

        var progress = new UserWorldProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = worldId,
            CurrentZoneId = startZone.Id,
            DistanceTraveledOnEdge = 0,
            UpdatedAt = DateTime.UtcNow
        };

        db.UserWorldProgresses.Add(progress);

        db.UserZoneUnlocks.Add(new UserZoneUnlock
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
