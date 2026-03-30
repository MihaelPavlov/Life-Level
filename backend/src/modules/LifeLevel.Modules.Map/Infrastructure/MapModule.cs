using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace LifeLevel.Modules.Map.Infrastructure;

public class MapProgressReadPortAdapter(DbContext db) : IMapProgressReadPort
{
    public async Task<Guid?> GetCurrentNodeIdAsync(Guid userId, CancellationToken ct = default)
    {
        return await db.Set<UserMapProgress>()
            .Where(p => p.UserId == userId)
            .Select(p => (Guid?)p.CurrentNodeId)
            .FirstOrDefaultAsync(ct);
    }
}

public class MapNodeCountPortAdapter(DbContext db) : IMapNodeCountPort
{
    public async Task<Dictionary<Guid, int>> GetNodeCountsByZoneIdsAsync(IEnumerable<Guid> zoneIds, CancellationToken ct = default)
    {
        var ids = zoneIds.ToHashSet();
        return await db.Set<MapNode>()
            .Where(n => n.WorldZoneId.HasValue && ids.Contains(n.WorldZoneId!.Value))
            .GroupBy(n => n.WorldZoneId!.Value)
            .Select(g => new { ZoneId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ZoneId, x => x.Count, ct);
    }
}

public class MapNodeCompletedCountPortAdapter(DbContext db) : IMapNodeCompletedCountPort
{
    public async Task<Dictionary<Guid, int>> GetCompletedNodeCountsByZoneIdsAsync(
        Guid userId, IEnumerable<Guid> zoneIds, CancellationToken ct = default)
    {
        var ids = zoneIds.ToHashSet();
        return await db.Set<UserNodeUnlock>()
            .Where(u => u.UserId == userId)
            .Join(
                db.Set<MapNode>(),
                u => u.MapNodeId,
                n => n.Id,
                (u, n) => n.WorldZoneId)
            .Where(zoneId => zoneId.HasValue && ids.Contains(zoneId!.Value))
            .GroupBy(zoneId => zoneId!.Value)
            .Select(g => new { ZoneId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ZoneId, x => x.Count, ct);
    }
}

public static class MapModule
{
    public static IServiceCollection AddMapModule(this IServiceCollection services)
    {
        services.AddScoped<IMapProgressReadPort, MapProgressReadPortAdapter>();
        services.AddScoped<IMapNodeCountPort, MapNodeCountPortAdapter>();
        services.AddScoped<IMapNodeCompletedCountPort, MapNodeCompletedCountPortAdapter>();
        return services;
    }
}
