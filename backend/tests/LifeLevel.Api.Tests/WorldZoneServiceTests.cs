using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

// Type alias: 'WorldZone' class name conflicts with the 'LifeLevel.Modules.WorldZone' namespace
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using UserWorldProgressEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserWorldProgress;
using UserZoneUnlockEntity = LifeLevel.Modules.WorldZone.Domain.Entities.UserZoneUnlock;

namespace LifeLevel.Api.Tests;

file sealed class NoOpCharacterXpPort : ICharacterXpPort
{
    public Task AwardXpAsync(Guid u, string s, string e, string d, long xp, CancellationToken ct = default)
        => Task.CompletedTask;
}

file sealed class DbCharacterLevelReadPort(DbContext db) : ICharacterLevelReadPort
{
    public async Task<int> GetLevelAsync(Guid userId, CancellationToken ct = default)
        => await db.Set<Character>()
            .Where(c => c.UserId == userId)
            .Select(c => c.Level)
            .FirstOrDefaultAsync(ct);
}

public class WorldZoneServiceTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private static WorldZoneService CreateService(AppDbContext db)
        => new WorldZoneService(db, new NoOpCharacterXpPort(), new DbCharacterLevelReadPort(db));

    // ──────────────────────────────────────────────────────────────────────────
    // Test 1: GetFullWorldAsync returns all zones with correct user state
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetFullWorldAsync_ReturnsAllZonesWithUserState()
    {
        var db = CreateDb(nameof(GetFullWorldAsync_ReturnsAllZonesWithUserState));

        var worldId = Guid.NewGuid();
        var world = new World { Id = worldId, Name = "Test World", IsActive = true };
        db.Worlds.Add(world);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test", Email = "test@test.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 5 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Zone 1", IsStartZone = true, LevelRequirement = 1 };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Zone 2", IsStartZone = false, LevelRequirement = 3 };
        db.WorldZones.AddRange(zone1, zone2);

        var edge = new WorldZoneEdge { Id = Guid.NewGuid(), FromZoneId = zone1.Id, ToZoneId = zone2.Id, DistanceKm = 10 };
        db.WorldZoneEdges.Add(edge);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = worldId,
            CurrentZoneId = zone1.Id,
            DistanceTraveledOnEdge = 0
        };
        db.UserWorldProgresses.Add(progress);

        var unlock = new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id,
            UnlockedAt = DateTime.UtcNow
        };
        db.UserZoneUnlocks.Add(unlock);

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.GetFullWorldAsync(userId);

        Assert.Equal(2, result.Zones.Count);
        Assert.Equal(5, result.CharacterLevel);

        var z1Dto = result.Zones.Single(z => z.Id == zone1.Id);
        Assert.True(z1Dto.UserState!.IsUnlocked);
        Assert.True(z1Dto.UserState.IsCurrentZone);
        Assert.False(z1Dto.UserState.IsDestination);
        Assert.True(z1Dto.UserState.IsLevelMet);

        var z2Dto = result.Zones.Single(z => z.Id == zone2.Id);
        Assert.False(z2Dto.UserState!.IsUnlocked);
        Assert.False(z2Dto.UserState.IsCurrentZone);
        Assert.True(z2Dto.UserState.IsLevelMet); // level 5 >= level req 3

        Assert.Single(result.Edges);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 2: GetFullWorldAsync initializes progress when missing
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task GetFullWorldAsync_InitializesProgressIfMissing()
    {
        var db = CreateDb(nameof(GetFullWorldAsync_InitializesProgressIfMissing));

        var worldId = Guid.NewGuid();
        var world = new World { Id = worldId, Name = "Test World", IsActive = true };
        db.Worlds.Add(world);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test2", Email = "test2@test.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 1 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var startZone = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Start Zone", IsStartZone = true, LevelRequirement = 1 };
        db.WorldZones.Add(startZone);

        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.GetFullWorldAsync(userId);

        // Progress should have been created
        var progress = await db.UserWorldProgresses.FirstOrDefaultAsync(p => p.UserId == userId);
        Assert.NotNull(progress);
        Assert.Equal(startZone.Id, progress.CurrentZoneId);

        // Start zone should be unlocked
        var unlock = await db.UserZoneUnlocks.FirstOrDefaultAsync(u => u.UserId == userId && u.WorldZoneId == startZone.Id);
        Assert.NotNull(unlock);

        var startZoneDto = result.Zones.Single(z => z.Id == startZone.Id);
        Assert.True(startZoneDto.UserState!.IsUnlocked);
        Assert.True(startZoneDto.UserState.IsCurrentZone);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 3: SetDestinationAsync sets edge and destination correctly
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task SetDestinationAsync_SetsEdgeAndDestination()
    {
        var db = CreateDb(nameof(SetDestinationAsync_SetsEdgeAndDestination));

        var worldId = Guid.NewGuid();
        var world = new World { Id = worldId, Name = "Test World", IsActive = true };
        db.Worlds.Add(world);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test3", Email = "test3@test.com", PasswordHash = "x" };
        db.Users.Add(user);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Zone 1", IsStartZone = true };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Zone 2" };
        db.WorldZones.AddRange(zone1, zone2);

        var edge = new WorldZoneEdge
        {
            Id = Guid.NewGuid(),
            FromZoneId = zone1.Id,
            ToZoneId = zone2.Id,
            DistanceKm = 5,
            IsBidirectional = true
        };
        db.WorldZoneEdges.Add(edge);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = worldId,
            CurrentZoneId = zone1.Id
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        await service.SetDestinationAsync(userId, zone2.Id);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == userId);
        Assert.Equal(zone2.Id, updated.DestinationZoneId);
        Assert.Equal(edge.Id, updated.CurrentEdgeId);
        Assert.Equal(0, updated.DistanceTraveledOnEdge);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 4: SetDestinationAsync throws when destination is not adjacent
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task SetDestinationAsync_ThrowsIfNotAdjacent()
    {
        var db = CreateDb(nameof(SetDestinationAsync_ThrowsIfNotAdjacent));

        var worldId = Guid.NewGuid();
        var world = new World { Id = worldId, Name = "Test World", IsActive = true };
        db.Worlds.Add(world);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test4", Email = "test4@test.com", PasswordHash = "x" };
        db.Users.Add(user);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Zone 1", IsStartZone = true };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Zone 2" };
        db.WorldZones.AddRange(zone1, zone2);
        // No edge between zone1 and zone2

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = worldId,
            CurrentZoneId = zone1.Id
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => service.SetDestinationAsync(userId, zone2.Id));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Test 5: AddDistanceAsync arrives at destination, unlocks zone
    // ──────────────────────────────────────────────────────────────────────────
    [Fact]
    public async Task AddDistanceAsync_ArrivesAtDestination()
    {
        var db = CreateDb(nameof(AddDistanceAsync_ArrivesAtDestination));

        var worldId = Guid.NewGuid();
        var world = new World { Id = worldId, Name = "Test World", IsActive = true };
        db.Worlds.Add(world);

        var userId = Guid.NewGuid();
        var user = new User { Id = userId, Username = "test5", Email = "test5@test.com", PasswordHash = "x" };
        var character = new Character { Id = Guid.NewGuid(), UserId = userId, Level = 1 };
        db.Users.Add(user);
        db.Characters.Add(character);

        var zone1 = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Zone 1", IsStartZone = true };
        var zone2 = new WorldZoneEntity { Id = Guid.NewGuid(), WorldId = worldId, Name = "Zone 2", TotalXp = 0 };
        db.WorldZones.AddRange(zone1, zone2);

        var edge = new WorldZoneEdge
        {
            Id = Guid.NewGuid(),
            FromZoneId = zone1.Id,
            ToZoneId = zone2.Id,
            DistanceKm = 5,
            IsBidirectional = true
        };
        db.WorldZoneEdges.Add(edge);

        var progress = new UserWorldProgressEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            WorldId = worldId,
            CurrentZoneId = zone1.Id,
            CurrentEdgeId = edge.Id,
            DestinationZoneId = zone2.Id,
            DistanceTraveledOnEdge = 0
        };
        db.UserWorldProgresses.Add(progress);
        db.UserZoneUnlocks.Add(new UserZoneUnlockEntity
        {
            UserId = userId,
            WorldZoneId = zone1.Id,
            UserWorldProgressId = progress.Id
        });

        await db.SaveChangesAsync();

        var service = CreateService(db);
        await service.AddDistanceAsync(userId, 5);

        var updated = await db.UserWorldProgresses.FirstAsync(p => p.UserId == userId);
        Assert.Equal(zone2.Id, updated.CurrentZoneId);
        Assert.Null(updated.CurrentEdgeId);
        Assert.Null(updated.DestinationZoneId);
        Assert.Equal(0, updated.DistanceTraveledOnEdge);

        var zone2Unlock = await db.UserZoneUnlocks
            .FirstOrDefaultAsync(u => u.UserId == userId && u.WorldZoneId == zone2.Id);
        Assert.NotNull(zone2Unlock);
    }
}
