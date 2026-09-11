using LifeLevel.Modules.Talents.Domain;
using LifeLevel.Modules.Talents.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

/// <summary>
/// Seeds the v1 talent catalog (16 talents) on first run. Idempotent — does nothing once any
/// Talent row exists. Pattern: SeasonSeeder / RankThresholdSeeder.
/// </summary>
public class TalentSeeder(AppDbContext db)
{
    public async Task SeedAsync()
    {
        if (await db.Set<Talent>().AnyAsync()) return;
        db.AddRange(TalentCatalog.Build());
        await db.SaveChangesAsync();
    }
}
