using LifeLevel.Modules.Character.Application.DTOs;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Character.Application.UseCases;

/// <summary>
/// Guided unlocks: every feature opens through play. Unlocks are derived from what the player has
/// already done (<see cref="IUnlockFactsReadPort"/>), so a lost event can never lose one, and a
/// player who already qualifies is simply unlocked the next time the list is read.
/// </summary>
public class UnlockService(DbContext db, IUnlockFactsReadPort facts, ICharacterXpPort xp)
{
    public const long TourXp = 25;

    public sealed record Definition(string Key, Func<UnlockFacts, bool> IsMet);

    /// <summary>The chain, in the order the player meets it.</summary>
    public static readonly IReadOnlyList<Definition> Catalog =
    [
        new("home", f => f.SetupComplete),
        new("achievements", f => f.ActivityCount >= 1),
        new("map", f => f.HasDistance),
        new("gear", f => f.ItemCount >= 1),
        new("chests", f => f.ZonesReached >= 2),
        new("talents", f => f.Level >= 3),
        new("shields", f => f.LongestStreak >= 3),
        new("bosses", f => f.BossSeen),
        new("guild", f => f.Level >= 5),
        new("modes", f => f.Level >= 10),
        new("delve", f => f.Level >= 15),
    ];

    public static bool IsKnownKey(string key) => Catalog.Any(d => d.Key == key);

    /// <summary>
    /// Unlocks anything newly earned and returns the whole chain.
    /// The first time a player is evaluated, everything they already qualify for is back-filled
    /// silently (seen and toured), so existing players aren't hit with a wall of ceremonies.
    /// The Home tour is the exception for a player who hasn't logged a workout yet: they are new.
    /// </summary>
    public async Task<UnlocksResponse> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var f = await facts.GetAsync(userId, ct);
        var rows = await db.Set<CharacterUnlock>().Where(u => u.UserId == userId).ToListAsync(ct);
        var firstEvaluation = rows.Count == 0;
        var now = DateTime.UtcNow;

        var added = false;
        foreach (var def in Catalog)
        {
            if (rows.Any(r => r.Key == def.Key) || !def.IsMet(f)) continue;
            var silent = firstEvaluation && !(def.Key == "home" && f.ActivityCount == 0);
            var row = new CharacterUnlock
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Key = def.Key,
                UnlockedAt = now,
                SeenAt = silent ? now : null,
                TouredAt = silent ? now : null,
            };
            db.Set<CharacterUnlock>().Add(row);
            rows.Add(row);
            added = true;
        }

        if (added)
        {
            try
            {
                await db.SaveChangesAsync(ct);
            }
            catch (DbUpdateException)
            {
                // Another request unlocked the same feature a moment earlier; read what it saved.
                db.ChangeTracker.Clear();
                rows = await db.Set<CharacterUnlock>().Where(u => u.UserId == userId).ToListAsync(ct);
            }
        }

        return new UnlocksResponse(Catalog.Select((def, i) =>
        {
            var row = rows.FirstOrDefault(r => r.Key == def.Key);
            return new UnlockDto(def.Key, i, row != null, row?.UnlockedAt, row?.SeenAt != null, row?.TouredAt != null);
        }).ToList());
    }

    /// <summary>The ceremony was shown (Show me or Later). Idempotent.</summary>
    public async Task MarkSeenAsync(Guid userId, string key, CancellationToken ct = default)
    {
        var row = await FindUnlockedAsync(userId, key, ct);
        if (row.SeenAt != null) return;
        row.SeenAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>The guided tour was finished. Awards <see cref="TourXp"/> the first time only.</summary>
    public async Task<UnlockTouredResponse> MarkTouredAsync(Guid userId, string key, CancellationToken ct = default)
    {
        var row = await FindUnlockedAsync(userId, key, ct);
        if (row.TouredAt != null) return new UnlockTouredResponse(key, 0);
        row.TouredAt = DateTime.UtcNow;
        row.SeenAt ??= row.TouredAt;
        await db.SaveChangesAsync(ct);
        await xp.AwardXpAsync(userId, "Tour", "🧭", $"Explored {key}", TourXp, ct);
        return new UnlockTouredResponse(key, TourXp);
    }

    private async Task<CharacterUnlock> FindUnlockedAsync(Guid userId, string key, CancellationToken ct)
    {
        if (!IsKnownKey(key)) throw new InvalidOperationException($"Unknown unlock '{key}'.");
        return await db.Set<CharacterUnlock>().FirstOrDefaultAsync(u => u.UserId == userId && u.Key == key, ct)
            ?? throw new InvalidOperationException($"'{key}' isn't unlocked yet.");
    }
}
