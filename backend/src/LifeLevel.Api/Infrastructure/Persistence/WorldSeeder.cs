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
    /// Dev-only: deactivates the current world and creates a fresh one.
    /// Old WorldZones and UserWorldProgress records are preserved on the old world.
    /// </summary>
    public async Task ClearAndReseedAsync()
    {
        // Deactivate old world(s)
        await db.Worlds
            .Where(w => w.IsActive)
            .ExecuteUpdateAsync(s => s.SetProperty(w => w.IsActive, false));

        // Null out MapNodes FK before edges/zones of old world might be cascade-deleted
        await db.MapNodes
            .Where(n => n.WorldZoneId != null)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.WorldZoneId, (Guid?)null));

        // Create new world
        var world = WorldSeedData.CreateWorld();
        world.Id = Guid.NewGuid(); // fresh ID to avoid PK conflict
        world.Name = $"World {DateTime.UtcNow:yyyy-MM-dd HH:mm}";
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
