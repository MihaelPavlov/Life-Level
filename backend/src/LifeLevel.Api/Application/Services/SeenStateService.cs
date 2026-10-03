using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Achievements.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Api.Application.Services;

public sealed record BossSeenView(Guid BossId, Guid? LastSeenTurnId, DateTime? LastSeenTurnAt);

public sealed class SeenStateService(AppDbContext db, IUserStateChangePort? stateChanges = null)
{
    public async Task MarkAchievementsAsync(Guid userId, IReadOnlyCollection<Guid> ids, CancellationToken ct)
    {
        if (ids.Count == 0) return;
        var rows = await db.Set<UserAchievement>().Where(x => x.UserId == userId
            && ids.Contains(x.AchievementId) && x.UnlockedAt != null && x.SeenAt == null).ToListAsync(ct);
        if (rows.Count == 0) return;
        var now = DateTime.UtcNow;
        foreach (var row in rows) row.SeenAt = now;
        await db.SaveChangesAsync(ct);
    }

    public async Task MarkTitlesAsync(Guid userId, IReadOnlyCollection<Guid> ids, CancellationToken ct)
    {
        if (ids.Count == 0) return;
        var characterId = await db.Characters.AsNoTracking().Where(x => x.UserId == userId)
            .Select(x => (Guid?)x.Id).FirstOrDefaultAsync(ct);
        if (characterId is null) return;
        var rows = await db.Set<CharacterTitle>().Where(x => x.CharacterId == characterId
            && ids.Contains(x.TitleId) && x.SeenAt == null).ToListAsync(ct);
        if (rows.Count == 0) return;
        var now = DateTime.UtcNow;
        foreach (var row in rows) row.SeenAt = now;
        await db.SaveChangesAsync(ct);
    }

    public Task<List<BossSeenView>> GetBossesAsync(Guid userId, CancellationToken ct) =>
        db.Set<UserBossState>().AsNoTracking().Where(x => x.UserId == userId)
            .Select(x => new BossSeenView(x.BossId, x.LastSeenTurnId, x.LastSeenTurnAt))
            .ToListAsync(ct);

    public async Task<BossSeenView?> MarkBossTurnAsync(Guid userId, Guid bossId, Guid turnId, CancellationToken ct)
    {
        var state = await db.Set<UserBossState>()
            .FirstOrDefaultAsync(x => x.UserId == userId && x.BossId == bossId, ct);
        if (state is null) return null;
        var turn = await db.Set<BossCombatTurn>().AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == turnId && x.UserBossStateId == state.Id, ct);
        if (turn is null) return null;
        if (db.Database.IsRelational())
        {
            var changed = await db.Set<UserBossState>().Where(x => x.Id == state.Id &&
                (x.LastSeenTurnAt == null || x.LastSeenTurnAt < turn.OccurredAt))
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(x => x.LastSeenTurnId, turn.Id)
                    .SetProperty(x => x.LastSeenTurnAt, turn.OccurredAt), ct);
            if (changed > 0 && stateChanges != null)
                await stateChanges.PublishUserAsync(userId, ["bosses"], ct);
            var current = await db.Set<UserBossState>().AsNoTracking()
                .FirstAsync(x => x.Id == state.Id, ct);
            return new BossSeenView(bossId, current.LastSeenTurnId, current.LastSeenTurnAt);
        }
        if (state.LastSeenTurnAt is null || turn.OccurredAt > state.LastSeenTurnAt)
        {
            state.LastSeenTurnId = turn.Id;
            state.LastSeenTurnAt = turn.OccurredAt;
            await db.SaveChangesAsync(ct);
        }
        return new BossSeenView(bossId, state.LastSeenTurnId, state.LastSeenTurnAt);
    }
}
