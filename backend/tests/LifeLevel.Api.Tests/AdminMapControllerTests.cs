using LifeLevel.Api.Controllers;
using LifeLevel.Api.Controllers.Admin;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using LifeLevel.SharedKernel.Enums;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Api.Tests;

public class AdminMapControllerTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var opts = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(dbName).Options;
        return new AppDbContext(opts);
    }

    private static AdminMapController NewController(AppDbContext db) => new(db);

    private static T Value<T>(IActionResult result) where T : class
    {
        return result switch
        {
            OkObjectResult ok => Assert.IsType<T>(ok.Value),
            _ => throw new Xunit.Sdk.XunitException($"Expected OkObjectResult with {typeof(T).Name}, got {result.GetType().Name}"),
        };
    }

    // ──────────── Worlds ────────────

    [Fact]
    public async Task CreateWorld_SetsActiveAndDeactivatesOthers()
    {
        var db = CreateDb(nameof(CreateWorld_SetsActiveAndDeactivatesOthers));
        db.Worlds.Add(new World { Id = Guid.NewGuid(), Name = "Old", IsActive = true });
        await db.SaveChangesAsync();

        var ctl = NewController(db);
        var result = await ctl.CreateWorld(new CreateWorldRequest("New", IsActive: true));

        var created = Value<WorldSummaryDto>(result);
        Assert.True(created.IsActive);

        var all = await db.Worlds.ToListAsync();
        Assert.Equal(2, all.Count);
        Assert.Single(all, w => w.IsActive && w.Name == "New");
        Assert.Single(all, w => !w.IsActive && w.Name == "Old");
    }

    [Fact]
    public async Task DeleteWorld_WithRegions_ReturnsBadRequest()
    {
        var db = CreateDb(nameof(DeleteWorld_WithRegions_ReturnsBadRequest));
        var worldId = Guid.NewGuid();
        db.Worlds.Add(new World { Id = worldId, Name = "W" });
        db.Regions.Add(new Region { Id = Guid.NewGuid(), WorldId = worldId, Name = "R" });
        await db.SaveChangesAsync();

        var result = await NewController(db).DeleteWorld(worldId);
        Assert.IsType<BadRequestObjectResult>(result);
        Assert.True(await db.Worlds.AnyAsync(w => w.Id == worldId));
    }

    // ──────────── Regions ────────────

    [Fact]
    public async Task CreateRegion_PersistsAllFieldsIncludingPinsJson()
    {
        var db = CreateDb(nameof(CreateRegion_PersistsAllFieldsIncludingPinsJson));
        var worldId = Guid.NewGuid();
        db.Worlds.Add(new World { Id = worldId, Name = "W" });
        await db.SaveChangesAsync();

        var req = new CreateRegionRequest(
            "Whispering Woods", "🌲", RegionTheme.Forest, 1, 3,
            "Misty and ancient.", "Forest Warden",
            RegionBossStatus.Locked, RegionStatus.Locked,
            new List<RegionPinDto> { new("Reward", "+300 XP") });

        var result = await NewController(db).CreateRegion(worldId, req);
        var created = Value<RegionSummaryDto>(result);

        Assert.Equal("Whispering Woods", created.Name);
        var row = await db.Regions.FirstAsync(r => r.Id == created.Id);
        Assert.Equal(RegionTheme.Forest, row.Theme);
        Assert.Equal("Forest Warden", row.BossName);
        Assert.Contains("Reward", row.PinsJson);
    }

    [Fact]
    public async Task DeleteRegion_WithZones_ReturnsBadRequest()
    {
        var db = CreateDb(nameof(DeleteRegion_WithZones_ReturnsBadRequest));
        var regionId = Guid.NewGuid();
        var worldId = Guid.NewGuid();
        db.Worlds.Add(new World { Id = worldId, Name = "W" });
        db.Regions.Add(new Region { Id = regionId, WorldId = worldId, Name = "R" });
        db.WorldZones.Add(new WorldZoneEntity { Id = Guid.NewGuid(), RegionId = regionId, Name = "Z", Emoji = "🚪", Type = WorldZoneType.Entry });
        await db.SaveChangesAsync();

        var result = await NewController(db).DeleteRegion(regionId);
        Assert.IsType<BadRequestObjectResult>(result);
        Assert.True(await db.Regions.AnyAsync(r => r.Id == regionId));
    }

    // ──────────── Zones ────────────

    [Fact]
    public async Task CreateZone_AsBoss_PersistsTimerFields()
    {
        var db = CreateDb(nameof(CreateZone_AsBoss_PersistsTimerFields));
        var (_, regionId) = await SeedWorldRegion(db);

        var req = new CreateZoneRequest(
            Name: "Forest Warden", Description: null, Emoji: "👹",
            Type: WorldZoneType.Boss, Tier: 5, LevelRequirement: 10, XpReward: 500,
            DistanceKm: 3, IsStartZone: false, BranchOfId: null,
            LoreTotal: null, NodesTotal: null,
            ChestRewardXp: null, ChestRewardDescription: null,
            DungeonBonusXp: null,
            BossTimerDays: 2, BossSuppressExpiry: false);

        var result = await NewController(db).CreateZone(regionId, req);
        var created = Value<ZoneSummaryDto>(result);
        Assert.Equal(WorldZoneType.Boss, created.Type);
        Assert.True(created.IsBoss);

        var row = await db.WorldZones.FirstAsync(z => z.Id == created.Id);
        Assert.Equal(2, row.BossTimerDays);
        Assert.False(row.BossSuppressExpiry);
        Assert.True(row.IsBoss);
    }

    [Fact]
    public async Task CreateZone_AsChest_PersistsRewardFields()
    {
        var db = CreateDb(nameof(CreateZone_AsChest_PersistsRewardFields));
        var (_, regionId) = await SeedWorldRegion(db);

        var req = new CreateZoneRequest(
            Name: "Hidden Shrine", Description: null, Emoji: "🗝️",
            Type: WorldZoneType.Chest, Tier: 2, LevelRequirement: 1, XpReward: 0,
            DistanceKm: 2, IsStartZone: false, BranchOfId: null,
            LoreTotal: null, NodesTotal: null,
            ChestRewardXp: 300, ChestRewardDescription: "A weathered chest",
            DungeonBonusXp: null,
            BossTimerDays: null, BossSuppressExpiry: null);

        var result = await NewController(db).CreateZone(regionId, req);
        var created = Value<ZoneSummaryDto>(result);

        var row = await db.WorldZones.FirstAsync(z => z.Id == created.Id);
        Assert.Equal(300, row.ChestRewardXp);
        Assert.Equal("A weathered chest", row.ChestRewardDescription);
        Assert.Null(row.BossTimerDays);
    }

    [Fact]
    public async Task CreateZone_AsDungeon_AllowsAddingFloors()
    {
        var db = CreateDb(nameof(CreateZone_AsDungeon_AllowsAddingFloors));
        var (_, regionId) = await SeedWorldRegion(db);
        var ctl = NewController(db);

        var zoneReq = new CreateZoneRequest(
            Name: "Pale Hollow", Description: null, Emoji: "🏰",
            Type: WorldZoneType.Dungeon, Tier: 4, LevelRequirement: 5, XpReward: 0,
            DistanceKm: 1, IsStartZone: false, BranchOfId: null,
            LoreTotal: null, NodesTotal: null,
            ChestRewardXp: null, ChestRewardDescription: null,
            DungeonBonusXp: 400,
            BossTimerDays: null, BossSuppressExpiry: null);
        var zone = Value<ZoneSummaryDto>(await ctl.CreateZone(regionId, zoneReq));

        var floorReq = new CreateFloorRequest(1, ActivityType.Running, DungeonFloorTargetKind.DistanceKm, 2.0, "Approach", "🏃");
        var floor = Value<FloorDto>(await ctl.CreateFloor(zone.Id, floorReq));

        Assert.Equal(1, floor.Ordinal);
        Assert.Equal(2.0, floor.TargetValue);
        Assert.Equal(ActivityType.Running, floor.ActivityType);
        Assert.Equal(1, await db.WorldZoneDungeonFloors.CountAsync(f => f.WorldZoneId == zone.Id));
    }

    [Fact]
    public async Task UpdateZone_ChangingTypeFromStandardToBoss_ClearsIrrelevantFieldsAndSetsIsBossFlag()
    {
        var db = CreateDb(nameof(UpdateZone_ChangingTypeFromStandardToBoss_ClearsIrrelevantFieldsAndSetsIsBossFlag));
        var (_, regionId) = await SeedWorldRegion(db);

        // Seed a Chest zone with chest fields set.
        var zoneId = Guid.NewGuid();
        db.WorldZones.Add(new WorldZoneEntity
        {
            Id = zoneId, RegionId = regionId, Name = "Placeholder", Emoji = "🗝️",
            Type = WorldZoneType.Chest, Tier = 1, ChestRewardXp = 100, ChestRewardDescription = "x",
        });
        await db.SaveChangesAsync();

        var updateReq = new UpdateZoneRequest(
            Name: "Now a boss", Description: null, Emoji: "👹",
            Type: WorldZoneType.Boss, Tier: 5, LevelRequirement: 10, XpReward: 500,
            DistanceKm: 3, IsStartZone: false, BranchOfId: null,
            LoreTotal: null, NodesTotal: null,
            ChestRewardXp: 999, ChestRewardDescription: "should be ignored",
            DungeonBonusXp: null,
            BossTimerDays: 7, BossSuppressExpiry: false);

        var result = await NewController(db).UpdateZone(zoneId, updateReq);
        Assert.IsType<NoContentResult>(result);

        var row = await db.WorldZones.FirstAsync(z => z.Id == zoneId);
        Assert.Equal(WorldZoneType.Boss, row.Type);
        Assert.True(row.IsBoss);
        Assert.Null(row.ChestRewardXp);
        Assert.Null(row.ChestRewardDescription);
        Assert.Equal(7, row.BossTimerDays);
    }

    // ──────────── Edges ────────────

    [Fact]
    public async Task CreateEdge_RejectsDuplicateReverseEdge()
    {
        var db = CreateDb(nameof(CreateEdge_RejectsDuplicateReverseEdge));
        var (_, regionId) = await SeedWorldRegion(db);
        var z1 = await AddZone(db, regionId, "A", WorldZoneType.Entry);
        var z2 = await AddZone(db, regionId, "B", WorldZoneType.Standard);

        var ctl = NewController(db);
        await ctl.CreateEdge(new CreateEdgeRequest(z1.Id, z2.Id, 2, true));

        var result = await ctl.CreateEdge(new CreateEdgeRequest(z2.Id, z1.Id, 2, true));
        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Equal(1, await db.WorldZoneEdges.CountAsync());
    }

    [Fact]
    public async Task DeleteEdge_NullsCurrentEdgeIdOnUserProgress()
    {
        var db = CreateDb(nameof(DeleteEdge_NullsCurrentEdgeIdOnUserProgress));
        var (worldId, regionId) = await SeedWorldRegion(db);
        var z1 = await AddZone(db, regionId, "A", WorldZoneType.Entry);
        var z2 = await AddZone(db, regionId, "B", WorldZoneType.Standard);

        var ctl = NewController(db);
        var edgeDto = Value<EdgeDto>(await ctl.CreateEdge(new CreateEdgeRequest(z1.Id, z2.Id, 2, true)));

        var userId = Guid.NewGuid();
        db.Users.Add(new User { Id = userId, Username = "u", Email = "u@x", PasswordHash = "x" });
        db.UserWorldProgresses.Add(new UserWorldProgress
        {
            Id = Guid.NewGuid(), UserId = userId, WorldId = worldId,
            CurrentZoneId = z1.Id, CurrentEdgeId = edgeDto.Id,
            DistanceTraveledOnEdge = 1.2, DestinationZoneId = z2.Id,
        });
        await db.SaveChangesAsync();

        var delRes = await ctl.DeleteEdge(edgeDto.Id);
        Assert.IsType<NoContentResult>(delRes);

        var prog = await db.UserWorldProgresses.FirstAsync(p => p.UserId == userId);
        Assert.Null(prog.CurrentEdgeId);
        Assert.Null(prog.DestinationZoneId);
        Assert.Equal(0, prog.DistanceTraveledOnEdge);
    }

    // ──────────── Floors ────────────

    [Fact]
    public async Task CreateFloor_OnNonDungeonZone_ReturnsBadRequest()
    {
        var db = CreateDb(nameof(CreateFloor_OnNonDungeonZone_ReturnsBadRequest));
        var (_, regionId) = await SeedWorldRegion(db);
        var zone = await AddZone(db, regionId, "Not a dungeon", WorldZoneType.Standard);

        var req = new CreateFloorRequest(1, ActivityType.Running, DungeonFloorTargetKind.DistanceKm, 1, "F1", "🏃");
        var result = await NewController(db).CreateFloor(zone.Id, req);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Equal(0, await db.WorldZoneDungeonFloors.CountAsync());
    }

    [Fact]
    public async Task CreateFloor_EnforcesUniqueOrdinalPerZone()
    {
        var db = CreateDb(nameof(CreateFloor_EnforcesUniqueOrdinalPerZone));
        var (_, regionId) = await SeedWorldRegion(db);
        var zone = await AddZone(db, regionId, "Dungeon", WorldZoneType.Dungeon);

        var ctl = NewController(db);
        var first = await ctl.CreateFloor(zone.Id, new CreateFloorRequest(1, ActivityType.Running, DungeonFloorTargetKind.DistanceKm, 1, "F1", "🏃"));
        Assert.IsType<OkObjectResult>(first);

        var dup = await ctl.CreateFloor(zone.Id, new CreateFloorRequest(1, ActivityType.Gym, DungeonFloorTargetKind.DurationMinutes, 20, "F1-dup", "💪"));
        Assert.IsType<BadRequestObjectResult>(dup);

        Assert.Equal(1, await db.WorldZoneDungeonFloors.CountAsync());
    }

    // ──────────── Enums ────────────

    [Fact]
    public void GetEnums_ReturnsAllWorldZoneTypesAndRegionThemes()
    {
        var db = CreateDb(nameof(GetEnums_ReturnsAllWorldZoneTypesAndRegionThemes));
        var result = NewController(db).GetEnums();
        var payload = Value<EnumsDto>(result);
        Assert.Equal(Enum.GetValues<WorldZoneType>().Length, payload.WorldZoneTypes.Count);
        Assert.Equal(Enum.GetValues<RegionTheme>().Length, payload.RegionThemes.Count);
        Assert.Contains(payload.WorldZoneTypes, o => o.Name == "Dungeon");
        Assert.Contains(payload.RegionThemes, o => o.Name == "Forest");
    }

    // ──────────── Helpers ────────────

    private static async Task<(Guid worldId, Guid regionId)> SeedWorldRegion(AppDbContext db)
    {
        var worldId = Guid.NewGuid();
        var regionId = Guid.NewGuid();
        db.Worlds.Add(new World { Id = worldId, Name = "World", IsActive = true });
        db.Regions.Add(new Region
        {
            Id = regionId, WorldId = worldId, Name = "Region", Emoji = "🌲",
            Theme = RegionTheme.Forest, ChapterIndex = 1,
        });
        await db.SaveChangesAsync();
        return (worldId, regionId);
    }

    private static async Task<WorldZoneEntity> AddZone(AppDbContext db, Guid regionId, string name, WorldZoneType type)
    {
        var z = new WorldZoneEntity
        {
            Id = Guid.NewGuid(), RegionId = regionId, Name = name, Emoji = "•",
            Type = type, Tier = 1, IsBoss = type == WorldZoneType.Boss,
        };
        db.WorldZones.Add(z);
        await db.SaveChangesAsync();
        return z;
    }
}
