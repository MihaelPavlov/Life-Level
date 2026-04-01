using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Data;
using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class TitleSeeder(AppDbContext db)
{
    public async Task SeedAsync()
    {
        foreach (var (id, emoji, name, unlockCondition, unlockCriteria, sortOrder) in TitleCatalog.Titles)
        {
            if (await db.Titles.AnyAsync(t => t.Id == id)) continue;

            db.Titles.Add(new Title
            {
                Id = id,
                Emoji = emoji,
                Name = name,
                UnlockCondition = unlockCondition,
                UnlockCriteria = unlockCriteria,
                SortOrder = sortOrder,
            });
        }

        await db.SaveChangesAsync();
    }
}
