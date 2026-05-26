using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public class RankThresholdSeeder(AppDbContext db)
{
    private static readonly (string Rank, string DisplayName, string Description, int BossesRequired)[] Defaults =
    [
        ("Novice",   "Novice",   "Starting rank — all new players begin here",              0),
        ("Warrior",  "Warrior",  "First milestone — proves commitment to the game",         1),
        ("Veteran",  "Veteran",  "Mid-tier rank — seasoned adventurer",                     3),
        ("Champion", "Champion", "High rank — only dedicated players reach this",           8),
        ("Legend",   "Legend",   "Ultimate rank — the top of the ladder",                  18),
    ];

    public async Task SeedAsync()
    {
        var existing = await db.RankThresholds.ToListAsync();

        if (existing.Count == 0)
        {
            foreach (var (rank, displayName, description, required) in Defaults)
            {
                db.RankThresholds.Add(new RankThreshold
                {
                    Id = Guid.NewGuid(),
                    Rank = rank,
                    DisplayName = displayName,
                    Description = description,
                    BossesRequired = required,
                });
            }
        }
        else
        {
            // Backfill DisplayName/Description for rows that were seeded before those columns existed
            bool dirty = false;
            foreach (var row in existing)
            {
                var defaults = Defaults.FirstOrDefault(d => d.Rank == row.Rank);
                if (defaults == default) continue;
                if (string.IsNullOrEmpty(row.DisplayName))
                {
                    row.DisplayName = defaults.DisplayName;
                    dirty = true;
                }
                if (string.IsNullOrEmpty(row.Description))
                {
                    row.Description = defaults.Description;
                    dirty = true;
                }
            }
            if (!dirty) return;
        }

        await db.SaveChangesAsync();
    }
}
