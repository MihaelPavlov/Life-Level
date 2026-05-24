using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public class RankThresholdSeeder(AppDbContext db)
{
    private static readonly (string Rank, int BossesRequired)[] Defaults =
    [
        ("Novice",   0),
        ("Warrior",  1),
        ("Veteran",  3),
        ("Champion", 8),
        ("Legend",   18),
    ];

    public async Task SeedAsync()
    {
        if (await db.RankThresholds.AnyAsync()) return;

        foreach (var (rank, required) in Defaults)
        {
            db.RankThresholds.Add(new RankThreshold
            {
                Id = Guid.NewGuid(),
                Rank = rank,
                BossesRequired = required,
            });
        }

        await db.SaveChangesAsync();
    }
}
