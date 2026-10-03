using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Activity.Domain.Entities;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Guild.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using GuildEntity = LifeLevel.Modules.Guild.Domain.Entities.Guild;

namespace LifeLevel.Api.Tests;

public class LeaderboardReadAdapterTests
{
    private static readonly DateTime WeekStart = new(2026, 9, 28, 0, 0, 0, DateTimeKind.Utc);

    [Fact]
    public async Task WeeklyXp_CountsOnlyThisWeek_AndSkipsUnfinishedSetups()
    {
        await using var db = CreateDb();
        var (me, meChar) = AddPlayer(db, "me");
        var (_, auraChar) = AddPlayer(db, "aura");
        AddPlayer(db, "newbie", setupComplete: false);
        db.Add(new XpHistoryEntry { CharacterId = meChar, Xp = 300, EarnedAt = WeekStart.AddDays(1) });
        db.Add(new XpHistoryEntry { CharacterId = meChar, Xp = 999, EarnedAt = WeekStart.AddDays(-1) });
        db.Add(new XpHistoryEntry { CharacterId = auraChar, Xp = 500, EarnedAt = WeekStart.AddHours(2) });
        await db.SaveChangesAsync();

        var pool = await Adapter(db).GetPoolAsync(me, LeaderboardScope.Global, LeaderboardMetric.Xp, WeekStart);

        Assert.True(pool.Available);
        Assert.Equal(2, pool.Entries.Count);
        Assert.Equal(300, pool.Entries.Single(e => e.Username == "me").Score);
        Assert.Equal(500, pool.Entries.Single(e => e.Username == "aura").Score);
    }

    [Fact]
    public async Task WeeklyKm_SumsActivityDistance()
    {
        await using var db = CreateDb();
        var (me, meChar) = AddPlayer(db, "me");
        db.Add(new Activity { CharacterId = meChar, DistanceKm = 5.25, LoggedAt = WeekStart.AddDays(2) });
        db.Add(new Activity { CharacterId = meChar, DistanceKm = 3, LoggedAt = WeekStart.AddDays(3) });
        await db.SaveChangesAsync();

        var pool = await Adapter(db).GetPoolAsync(me, LeaderboardScope.Global, LeaderboardMetric.Km, WeekStart);

        Assert.Equal(8.3, pool.Entries.Single().Score);
    }

    [Fact]
    public async Task Guild_IsUnavailableWithoutAGuild_AndOnlyListsMembers()
    {
        await using var db = CreateDb();
        var (me, _) = AddPlayer(db, "me");
        var (mate, _) = AddPlayer(db, "mate");
        AddPlayer(db, "stranger");
        await db.SaveChangesAsync();
        var adapter = Adapter(db);

        Assert.False((await adapter.GetPoolAsync(me, LeaderboardScope.Guild, LeaderboardMetric.Xp, WeekStart)).Available);

        var guild = new GuildEntity { Name = "Iron Wolves" };
        db.Add(guild);
        db.Add(new GuildMember { GuildId = guild.Id, UserId = me });
        db.Add(new GuildMember { GuildId = guild.Id, UserId = mate });
        await db.SaveChangesAsync();

        var pool = await adapter.GetPoolAsync(me, LeaderboardScope.Guild, LeaderboardMetric.Xp, WeekStart);
        Assert.Equal("Iron Wolves", pool.ContextName);
        Assert.Equal(["mate", "me"], pool.Entries.Select(e => e.Username).Order());
    }

    [Fact]
    public async Task Power_ComesFromCombatStats()
    {
        await using var db = CreateDb();
        var (me, _) = AddPlayer(db, "me");
        await db.SaveChangesAsync();

        var pool = await Adapter(db, power: 1234).GetPoolAsync(me, LeaderboardScope.Global, LeaderboardMetric.Power, WeekStart);

        Assert.Equal(1234, pool.Entries.Single().Score);
    }

    private static (Guid UserId, Guid CharacterId) AddPlayer(AppDbContext db, string name, bool setupComplete = true)
    {
        var user = new User { Username = name, Email = $"{name}@test" };
        var character = new Character { Id = Guid.NewGuid(), UserId = user.Id, IsSetupComplete = setupComplete, Level = 3 };
        db.Add(user);
        db.Add(character);
        return (user.Id, character.Id);
    }

    private static LeaderboardReadAdapter Adapter(AppDbContext db, int power = 0) =>
        new(db, new FixedPower(power));

    private static AppDbContext CreateDb() => new(
        new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private sealed class FixedPower(int power) : ICharacterCombatStatsReadPort
    {
        public Task<CombatStatsSnapshot> GetCombatStatsAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(new CombatStatsSnapshot(0, 0, 0, power, 1));
    }
}
