using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Talents.Application.UseCases;
using LifeLevel.Modules.Talents.Domain.Entities;
using LifeLevel.Modules.Talents.Domain.Enums;
using LifeLevel.Modules.Identity.Domain.Entities;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class AmbientTransactionTests
{
    [Fact]
    public async Task TalentDraw_ReusesAmbientRelationalTransaction()
    {
        await using var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(connection).Options;
        await using var db = new AppDbContext(options);
        await db.Database.EnsureCreatedAsync();

        var userId = Guid.NewGuid();
        db.Add(new User
        {
            Id = userId,
            Username = $"ambient-{userId:N}",
            Email = $"{userId:N}@example.test",
            NormalizedEmail = $"{userId:N}@EXAMPLE.TEST",
        });
        var talent = new Talent
        {
            Key = "ambient", Name = "Ambient", Description = "test",
            IconKey = "stat_strength", Rarity = TalentRarity.Common,
            EffectType = TalentEffectType.StatStrength, PerLevelValue = 1,
            MaxLevel = 10, DrawWeight = 100, IsActive = true,
        };
        db.Add(talent);
        db.Add(new UserTalent { UserId = userId, TalentId = talent.Id, Level = 1 });
        db.Add(new UserTalentWallet { UserId = userId, Coins = 1_000, TalentCrystals = 10 });
        await db.SaveChangesAsync();

        await using var outer = await db.Database.BeginTransactionAsync();
        var result = await new TalentService(db).DrawAsync(userId);

        Assert.Same(outer, db.Database.CurrentTransaction);
        Assert.Equal(2, result.Talent.Level);
        Assert.Single(await db.Set<TalentDrawEntry>().ToListAsync());
    }
}
