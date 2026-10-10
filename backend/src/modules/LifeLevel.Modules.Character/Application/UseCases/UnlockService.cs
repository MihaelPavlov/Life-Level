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
public class UnlockService(DbContext db, IUnlockFactsReadPort facts, IRewardCurrencyPort currency)
{
    /// <summary>Coins for finishing a feature's tour, once. Coins, not XP, so a tour can never
    /// trigger a level-up in the middle of a run of unlock ceremonies.</summary>
    public const int TourCoins = 25;

    /// <summary>
    /// Characters created before guided unlocks shipped are back-filled silently. Anyone newer
    /// (including a player whose onboarding import already met several conditions) gets every
    /// ceremony and tour.
    /// </summary>
    public static readonly DateTime BackFillBefore = new(2026, 9, 30, 0, 0, 0, DateTimeKind.Utc);

    /// <summary>
    /// Most features open when the player reaches their <paramref name="Tier"/> and performs their
    /// <paramref name="Action"/>. Milestone features can ignore the level and pacing gates while
    /// retaining their tier as display/order metadata.
    /// </summary>
    public sealed record Definition(
        string Key,
        int Tier,
        Func<UnlockFacts, bool> Action,
        bool RequiresTierLevel = true,
        bool ReleaseImmediately = false)
    {
        public bool IsMet(UnlockFacts f) =>
            (!RequiresTierLevel || f.Level >= Tier) && Action(f);
    }

    /// <summary>The path, in the order the player meets it (tier, then catalog order).</summary>
    public static readonly IReadOnlyList<Definition> Catalog =
    [
        new("home", 1, f => f.SetupComplete),
        new("map", 1, f => f.HasDistance),
        new("achievements", 2, f => f.ActivityCount >= 1),
        new("gear", 2, f => f.ItemCount >= 1),
        new("talents", 3, _ => true),
        new("shields", 3, f => f.LongestStreak >= 3),
        new("chests", 4, f => f.HasCompletedRegion,
            RequiresTierLevel: false, ReleaseImmediately: true),
        new("bosses", 4, f => f.BossSeen),
        new("ranks", 5, f => f.RankReached || f.TitlesEarned >= 1),
        new("leaderboard", 6, _ => true),
        new("guild", 8, _ => true),
        new("modes", 10, _ => true),
        new("delve", 15, _ => true),
    ];

    public static bool IsKnownKey(string key) => Catalog.Any(d => d.Key == key);

    public static int TierOf(string key) => Catalog.FirstOrDefault(d => d.Key == key)?.Tier ?? 0;

    /// <summary>
    /// Unlocks anything newly earned and returns the whole chain.
    /// The first time an existing player is evaluated, everything they already qualify for is
    /// back-filled silently (seen and toured), so they aren't hit with a wall of ceremonies.
    /// The Home tour is the exception for a player who hasn't logged a workout yet: they are new.
    /// Characters created after <see cref="BackFillBefore"/> are never back-filled; they are paced
    /// by <see cref="Releasable"/>.
    /// </summary>
    public async Task<UnlocksResponse> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var f = await facts.GetAsync(userId, ct);
        var rows = await db.Set<CharacterUnlock>().Where(u => u.UserId == userId).ToListAsync(ct);
        var backFill = rows.Count == 0 && (f.CharacterCreatedAt ?? DateTime.MinValue) < BackFillBefore;
        var now = DateTime.UtcNow;

        var candidates = Catalog.Where(d => d.IsMet(f) && rows.All(r => r.Key != d.Key)).ToList();
        if (!backFill)
        {
            var immediate = candidates.Where(d => d.ReleaseImmediately);
            var paced = Releasable(candidates.Where(d => !d.ReleaseImmediately).ToList(), rows, f);
            candidates = Catalog.Where(d => immediate.Contains(d) || paced.Contains(d)).ToList();
        }

        var added = false;
        foreach (var def in candidates)
        {
            var silent = backFill && !(def.Key == "home" && f.ActivityCount == 0);
            var row = new CharacterUnlock
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Key = def.Key,
                UnlockedAt = now,
                SeenAt = silent ? now : null,
                TouredAt = silent ? now : null,
                ActivityCountAtUnlock = f.ActivityCount,
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
            return new UnlockDto(def.Key, i, row != null, row?.UnlockedAt, row?.SeenAt != null, row?.TouredAt != null, def.Tier);
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

    /// <summary>The guided tour was finished. Awards <see cref="TourCoins"/> the first time only.</summary>
    public async Task<UnlockTouredResponse> MarkTouredAsync(Guid userId, string key, CancellationToken ct = default)
    {
        var row = await FindUnlockedAsync(userId, key, ct);
        if (row.TouredAt != null) return new UnlockTouredResponse(key, 0, 0);
        row.TouredAt = DateTime.UtcNow;
        row.SeenAt ??= row.TouredAt;
        await db.SaveChangesAsync(ct);
        await currency.AddCoinsAsync(userId, TourCoins, ct);
        return new UnlockTouredResponse(key, 0, TourCoins);
    }

    /// <summary>
    /// Pacing for players who aren't back-filled. Only the lowest tier among <paramref name="met"/>
    /// is released, so one moment never opens more than two features, and only when:
    /// <list type="bullet">
    /// <item>every earlier ceremony has been seen (the queue on the phone is empty), and</item>
    /// <item>it is tier 1, a feature of the same tier is already out (its partner just caught up),
    /// or the player logged a workout since the last release. A big workout that qualifies two
    /// tiers opens the second one on the next workout.</item>
    /// </list>
    /// </summary>
    public static List<Definition> Releasable(List<Definition> met, IReadOnlyCollection<CharacterUnlock> rows, UnlockFacts f)
    {
        if (met.Count == 0) return met;
        var released = rows.Where(r => r.Key != "home").ToList();
        if (released.Any(r => r.SeenAt == null)) return [];

        var tier = met.Min(d => d.Tier);
        var tierOpen = released.Any(r => TierOf(r.Key) == tier);
        var workoutSince = released.Count == 0 || f.ActivityCount > released.Max(r => r.ActivityCountAtUnlock);
        return tier == 1 || tierOpen || workoutSince ? met.Where(d => d.Tier == tier).ToList() : [];
    }

    private async Task<CharacterUnlock> FindUnlockedAsync(Guid userId, string key, CancellationToken ct)
    {
        if (!IsKnownKey(key)) throw new InvalidOperationException($"Unknown unlock '{key}'.");
        return await db.Set<CharacterUnlock>().FirstOrDefaultAsync(u => u.UserId == userId && u.Key == key, ct)
            ?? throw new InvalidOperationException($"'{key}' isn't unlocked yet.");
    }
}
