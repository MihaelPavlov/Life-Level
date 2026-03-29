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

public static class MapModule
{
    public static IServiceCollection AddMapModule(this IServiceCollection services)
    {
        services.AddScoped<IMapProgressReadPort, MapProgressReadPortAdapter>();
        return services;
    }
}
