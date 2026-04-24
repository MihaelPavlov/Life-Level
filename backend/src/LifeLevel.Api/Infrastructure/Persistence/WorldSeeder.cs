using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public class WorldSeeder(AppDbContext db)
{
    /// <summary>
    /// Idempotent — only seeds if no world exists yet. Safe to call on every startup.
    /// </summary>
    public async Task SeedAsync()
    {
        if (!await db.Worlds.AnyAsync())
        {
            var world = WorldSeedData.CreateWorld();
            db.Worlds.Add(world);
            await db.SaveChangesAsync();

            db.Regions.AddRange(WorldSeedData.CreateRegions(world.Id));
            await db.SaveChangesAsync();

            db.WorldZones.AddRange(WorldSeedData.CreateZones());
            await db.SaveChangesAsync();

            db.WorldZoneEdges.AddRange(WorldSeedData.CreateEdges());
            await db.SaveChangesAsync();

            db.WorldZoneDungeonFloors.AddRange(WorldSeedData.CreateDungeonFloors());
            await db.SaveChangesAsync();
        }

        // Minimal local-map seed: one start node per WorldZone so activity
        // logging and MapService.InitializeUserProgressAsync succeed. The full
        // per-zone node graph (Boss / Chest / DungeonPortal / Crossroads) is a
        // follow-up when those adventure modules are re-designed. Top up
        // independently of World so older DBs get patched on startup.
        if (!await db.MapNodes.AnyAsync())
        {
            db.MapNodes.AddRange(WorldSeedData.CreateMapStartNodes());
            await db.SaveChangesAsync();
        }
    }

    /// <summary>
    /// Dev-only: wipes world/region/zone data and reseeds from scratch. Leaves
    /// sub-map (MapNode/Boss/Chest/...) tables alone — they're no longer seeded
    /// and will be empty on a fresh install.
    /// </summary>
    public async Task ClearAndReseedAsync()
    {
        // Delete in dependency order (leaf tables first, then parents)
        // Sub-map state first (if any legacy rows exist).
        await db.UserBossStates.ExecuteDeleteAsync();
        await db.UserChestStates.ExecuteDeleteAsync();
        await db.UserDungeonStates.ExecuteDeleteAsync();
        await db.UserCrossroadsStates.ExecuteDeleteAsync();
        await db.UserNodeUnlocks.ExecuteDeleteAsync();
        await db.UserMapProgresses.ExecuteDeleteAsync();
        await db.DungeonFloors.ExecuteDeleteAsync();
        await db.CrossroadsPaths.ExecuteDeleteAsync();
        await db.Bosses.ExecuteDeleteAsync();
        await db.Chests.ExecuteDeleteAsync();
        await db.DungeonPortals.ExecuteDeleteAsync();
        await db.Crossroads.ExecuteDeleteAsync();
        await db.MapEdges.ExecuteDeleteAsync();
        await db.MapNodes.ExecuteDeleteAsync();

        // World-zone user state (before edges — CurrentEdgeId FK).
        // Chest + dungeon user state first (refers to WorldZoneDungeonFloor).
        await db.UserWorldDungeonFloorStates.ExecuteDeleteAsync();
        await db.UserWorldDungeonStates.ExecuteDeleteAsync();
        await db.UserWorldChestStates.ExecuteDeleteAsync();
        await db.WorldZoneDungeonFloors.ExecuteDeleteAsync();

        await db.UserPathChoices.ExecuteDeleteAsync();
        await db.UserZoneUnlocks.ExecuteDeleteAsync();
        await db.UserWorldProgresses.ExecuteDeleteAsync();
        await db.WorldZoneEdges.ExecuteDeleteAsync();
        await db.WorldZones.ExecuteDeleteAsync();
        await db.Regions.ExecuteDeleteAsync();
        await db.Worlds.ExecuteDeleteAsync();

        // Seed fresh.
        var world = WorldSeedData.CreateWorld();
        db.Worlds.Add(world);
        await db.SaveChangesAsync();

        db.Regions.AddRange(WorldSeedData.CreateRegions(world.Id));
        await db.SaveChangesAsync();

        db.WorldZones.AddRange(WorldSeedData.CreateZones());
        await db.SaveChangesAsync();

        db.WorldZoneEdges.AddRange(WorldSeedData.CreateEdges());
        await db.SaveChangesAsync();

        db.WorldZoneDungeonFloors.AddRange(WorldSeedData.CreateDungeonFloors());
        await db.SaveChangesAsync();

        db.MapNodes.AddRange(WorldSeedData.CreateMapStartNodes());
        await db.SaveChangesAsync();
    }
}
