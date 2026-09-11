using LifeLevel.Modules.Seasons.Domain;
using LifeLevel.Modules.Seasons.Domain.Entities;
using LifeLevel.Modules.Seasons.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

/// <summary>
/// Seeds Season 1 "Trail of Embers" (Active, now .. now+56d) plus its 25×2 reward tiers on
/// first run. Idempotent — does nothing once any Season row exists. Pattern: RankThresholdSeeder.
/// </summary>
public class SeasonSeeder(AppDbContext db)
{
    public async Task SeedAsync()
    {
        if (await db.Set<Season>().AnyAsync()) return;

        var season = new Season
        {
            Id = Guid.NewGuid(),
            Number = 1,
            Name = SeasonOneCatalog.SeasonName,
            Theme = SeasonOneCatalog.Theme,
            StartsAt = DateTime.UtcNow,
            EndsAt = DateTime.UtcNow.AddDays(SeasonOneCatalog.DurationDays),
            State = SeasonState.Active,
            XpPerTier = SeasonOneCatalog.XpPerTier,
            TierCount = SeasonOneCatalog.TierCount,
            MilestoneTier = SeasonOneCatalog.MilestoneTier,
        };
        db.Add(season);
        db.AddRange(SeasonOneCatalog.Build(season.Id));
        await db.SaveChangesAsync();
    }
}
