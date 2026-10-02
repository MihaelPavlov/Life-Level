using LifeLevel.Modules.Activity.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Character.Domain;
using LifeLevel.Modules.Character.Domain.Data;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Streak.Domain.Entities;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;

namespace LifeLevel.Api.Infrastructure.Persistence;

/// <summary>Reads what the guided-unlock chain needs from the modules that own it.</summary>
public sealed class UnlockFactsReadAdapter(AppDbContext db) : IUnlockFactsReadPort
{
    public async Task<UnlockFacts> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().AsNoTracking()
            .Where(c => c.UserId == userId)
            .Select(c => new { c.Id, c.Level, c.IsSetupComplete, c.CreatedAt, c.Rank })
            .FirstOrDefaultAsync(ct);
        if (character == null) return new UnlockFacts(false, 0, false, 0, 0, 1, 0, false);

        var activities = db.Set<Activity>().AsNoTracking().Where(a => a.CharacterId == character.Id);
        var activityCount = await activities.CountAsync(ct);
        var hasDistance = activityCount > 0 && await activities.AnyAsync(a => a.DistanceKm > 0, ct);
        var itemCount = await db.Set<CharacterItem>().AsNoTracking()
            .CountAsync(i => i.CharacterId == character.Id, ct);
        var zonesReached = await db.Set<UserZoneUnlock>().AsNoTracking()
            .CountAsync(z => z.UserId == userId, ct);
        var longestStreak = await db.Set<Streak>().AsNoTracking()
            .Where(s => s.UserId == userId).Select(s => (int?)s.Longest).FirstOrDefaultAsync(ct) ?? 0;
        var bossSeen = await db.Set<UserBossState>().AsNoTracking()
            .AnyAsync(b => b.UserId == userId, ct);
        // The tutorial's Novice Adventurer title is handed out, not reached, so it doesn't count.
        var tutorialTitleId = TitleCatalog.KeyToId[TutorialStepRewards.NoviceTitleKey];
        var titlesEarned = await db.Set<CharacterTitle>().AsNoTracking()
            .CountAsync(t => t.CharacterId == character.Id && t.TitleId != tutorialTitleId, ct);
        var rankReached = !string.IsNullOrEmpty(character.Rank) && character.Rank != "Novice";

        return new UnlockFacts(
            character.IsSetupComplete, activityCount, hasDistance, itemCount,
            zonesReached, character.Level, longestStreak, bossSeen, character.CreatedAt,
            titlesEarned, rankReached);
    }
}
