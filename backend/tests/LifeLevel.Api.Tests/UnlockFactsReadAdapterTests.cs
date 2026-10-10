using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Enums;
using Microsoft.EntityFrameworkCore;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Api.Tests;

public class UnlockFactsReadAdapterTests
{
    [Theory]
    [InlineData(true, false)]
    [InlineData(false, true)]
    public async Task ResolvedRegionBoss_DerivesCompletedRegionFact(bool defeated, bool expired)
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var world = new World { Id = Guid.NewGuid(), Name = "World", IsActive = true };
        var region = new Region
        {
            Id = Guid.NewGuid(), WorldId = world.Id, World = world, Name = "First",
            Emoji = "🌲", Theme = RegionTheme.Forest, ChapterIndex = 1,
            LevelRequirement = 1, Lore = "Test", BossName = "Boss",
        };
        var zone = new WorldZoneEntity
        {
            Id = Guid.NewGuid(), RegionId = region.Id, Region = region,
            Name = "Boss", Emoji = "💀", Type = WorldZoneType.Boss, IsBoss = true,
        };
        var boss = new Boss
        {
            Id = Guid.NewGuid(), Name = "Boss", Icon = "💀", MaxHp = 100,
            WorldZoneId = zone.Id,
        };
        db.AddRange(
            new Character { Id = Guid.NewGuid(), UserId = userId, Level = 1 },
            world, region, zone, boss,
            new UserBossState
            {
                Id = Guid.NewGuid(), UserId = userId, BossId = boss.Id, Boss = boss,
                IsDefeated = defeated, IsExpired = expired,
            });
        await db.SaveChangesAsync();

        var facts = await new UnlockFactsReadAdapter(db).GetAsync(userId);

        Assert.True(facts.HasCompletedRegion);
    }

    [Fact]
    public async Task UnresolvedRegionBoss_DoesNotDeriveCompletedRegionFact()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        db.Characters.Add(new Character { Id = Guid.NewGuid(), UserId = userId, Level = 99 });
        await db.SaveChangesAsync();

        var facts = await new UnlockFactsReadAdapter(db).GetAsync(userId);

        Assert.False(facts.HasCompletedRegion);
    }

    [Fact]
    public async Task ResolvedNonRegionBoss_DoesNotDeriveCompletedRegionFact()
    {
        await using var db = CreateDb();
        var userId = Guid.NewGuid();
        var boss = new Boss
        {
            Id = Guid.NewGuid(), Name = "Trail blocker", Icon = "⚔️", MaxHp = 50,
            TrailEncounterTemplateId = Guid.NewGuid(),
        };
        db.AddRange(
            new Character { Id = Guid.NewGuid(), UserId = userId, Level = 99 },
            boss,
            new UserBossState
            {
                Id = Guid.NewGuid(), UserId = userId, BossId = boss.Id, Boss = boss,
                IsDefeated = true,
            });
        await db.SaveChangesAsync();

        var facts = await new UnlockFactsReadAdapter(db).GetAsync(userId);

        Assert.False(facts.HasCompletedRegion);
    }

    private static AppDbContext CreateDb() => new(
        new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);
}
