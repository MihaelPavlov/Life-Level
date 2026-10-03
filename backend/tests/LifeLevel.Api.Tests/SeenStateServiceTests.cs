using LifeLevel.Api.Application.Services;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Achievements.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class SeenStateServiceTests
{
    [Fact]
    public async Task Achievements_OnlyMarksUnlockedRowsOwnedByUser()
    {
        await using var db = CreateDb();
        var user = Guid.NewGuid();
        var other = Guid.NewGuid();
        var earned = new UserAchievement { UserId = user, AchievementId = Guid.NewGuid(), UnlockedAt = DateTime.UtcNow };
        var locked = new UserAchievement { UserId = user, AchievementId = Guid.NewGuid() };
        var foreign = new UserAchievement { UserId = other, AchievementId = Guid.NewGuid(), UnlockedAt = DateTime.UtcNow };
        db.UserAchievements.AddRange(earned, locked, foreign);
        await db.SaveChangesAsync();

        await new SeenStateService(db).MarkAchievementsAsync(user,
            [earned.AchievementId, locked.AchievementId, foreign.AchievementId], default);

        Assert.NotNull(earned.SeenAt);
        Assert.Null(locked.SeenAt);
        Assert.Null(foreign.SeenAt);
    }

    [Fact]
    public async Task Titles_OnlyMarksEarnedTitlesForCurrentCharacter()
    {
        await using var db = CreateDb();
        var user = Guid.NewGuid();
        var character = new Character { Id = Guid.NewGuid(), UserId = user };
        var other = new Character { Id = Guid.NewGuid(), UserId = Guid.NewGuid() };
        var owned = new CharacterTitle { Id = Guid.NewGuid(), CharacterId = character.Id, TitleId = Guid.NewGuid() };
        var foreign = new CharacterTitle { Id = Guid.NewGuid(), CharacterId = other.Id, TitleId = Guid.NewGuid() };
        db.Characters.AddRange(character, other);
        db.CharacterTitles.AddRange(owned, foreign);
        await db.SaveChangesAsync();

        await new SeenStateService(db).MarkTitlesAsync(user, [owned.TitleId, foreign.TitleId], default);

        Assert.NotNull(owned.SeenAt);
        Assert.Null(foreign.SeenAt);
    }

    [Fact]
    public async Task BossCursor_RejectsForeignTurnsAndNeverMovesBackwards()
    {
        await using var db = CreateDb();
        var user = Guid.NewGuid();
        var boss = Guid.NewGuid();
        var ownState = new UserBossState { Id = Guid.NewGuid(), UserId = user, BossId = boss };
        var foreignState = new UserBossState { Id = Guid.NewGuid(), UserId = Guid.NewGuid(), BossId = boss };
        var first = new BossCombatTurn { Id = Guid.NewGuid(), UserBossStateId = ownState.Id,
            OccurredAt = DateTime.UtcNow.AddMinutes(-2) };
        var latest = new BossCombatTurn { Id = Guid.NewGuid(), UserBossStateId = ownState.Id,
            OccurredAt = DateTime.UtcNow.AddMinutes(-1) };
        var foreign = new BossCombatTurn { Id = Guid.NewGuid(), UserBossStateId = foreignState.Id,
            OccurredAt = DateTime.UtcNow };
        db.UserBossStates.AddRange(ownState, foreignState);
        db.BossCombatTurns.AddRange(first, latest, foreign);
        await db.SaveChangesAsync();
        var seen = new SeenStateService(db);

        Assert.Null(await seen.MarkBossTurnAsync(user, boss, foreign.Id, default));
        await seen.MarkBossTurnAsync(user, boss, latest.Id, default);
        await seen.MarkBossTurnAsync(user, boss, first.Id, default);

        Assert.Equal(latest.Id, ownState.LastSeenTurnId);
        Assert.Equal(latest.OccurredAt, ownState.LastSeenTurnAt);
    }

    private static AppDbContext CreateDb() => new(
        new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
}
