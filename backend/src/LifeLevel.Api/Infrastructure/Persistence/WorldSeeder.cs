using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public class WorldSeeder(AppDbContext db)
{
    /// <summary>
    /// Idempotent — only seeds if no world exists yet. Safe to call on every startup.
    /// </summary>
    public async Task SeedAsync()
    {
        if (await db.Worlds.AnyAsync()) return;

        var world = WorldSeedData.CreateWorld();
        db.Worlds.Add(world);

        db.WorldZones.AddRange(WorldSeedData.CreateZones(world.Id));
        await db.SaveChangesAsync();

        db.WorldZoneEdges.AddRange(WorldSeedData.CreateEdges(world.Id));
        await db.SaveChangesAsync();

        db.MapNodes.AddRange(WorldSeedData.CreateMapNodes());
        await db.SaveChangesAsync();

        db.MapEdges.AddRange(WorldSeedData.CreateMapEdges());
        await db.SaveChangesAsync();
    }

    /// <summary>
    /// Dev-only: wipes all world/zone/map data and reseeds from scratch.
    /// Deletes in FK dependency order to avoid constraint violations.
    /// </summary>
    public async Task ClearAndReseedAsync()
    {
        // Delete in dependency order (leaf tables first, then parents)
        // User state tables that reference content nodes
        await db.UserBossStates.ExecuteDeleteAsync();
        await db.UserChestStates.ExecuteDeleteAsync();
        await db.UserDungeonStates.ExecuteDeleteAsync();
        await db.UserCrossroadsStates.ExecuteDeleteAsync();
        // User map progress tables that reference MapNodes
        await db.UserNodeUnlocks.ExecuteDeleteAsync();
        await db.UserMapProgresses.ExecuteDeleteAsync();
        // Content child tables
        await db.DungeonFloors.ExecuteDeleteAsync();
        await db.CrossroadsPaths.ExecuteDeleteAsync();
        // Content tables referencing MapNodes
        await db.Bosses.ExecuteDeleteAsync();
        await db.Chests.ExecuteDeleteAsync();
        await db.DungeonPortals.ExecuteDeleteAsync();
        await db.Crossroads.ExecuteDeleteAsync();
        // Map structure
        await db.MapEdges.ExecuteDeleteAsync();
        await db.MapNodes.ExecuteDeleteAsync();
        // World zone user state (must come before WorldZoneEdges due to CurrentEdgeId FK)
        await db.UserZoneUnlocks.ExecuteDeleteAsync();
        await db.UserWorldProgresses.ExecuteDeleteAsync();
        // World zone structure
        await db.WorldZoneEdges.ExecuteDeleteAsync();
        await db.WorldZones.ExecuteDeleteAsync();
        await db.Worlds.ExecuteDeleteAsync();

        // Seed fresh
        var world = WorldSeedData.CreateWorld();
        db.Worlds.Add(world);
        db.WorldZones.AddRange(WorldSeedData.CreateZones(world.Id));
        await db.SaveChangesAsync();

        db.WorldZoneEdges.AddRange(WorldSeedData.CreateEdges(world.Id));
        await db.SaveChangesAsync();

        db.MapNodes.AddRange(WorldSeedData.CreateMapNodes());
        await db.SaveChangesAsync();

        db.MapEdges.AddRange(WorldSeedData.CreateMapEdges());
        await db.SaveChangesAsync();
    }
}
