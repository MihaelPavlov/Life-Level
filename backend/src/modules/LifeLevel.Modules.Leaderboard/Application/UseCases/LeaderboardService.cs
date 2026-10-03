using System.Text.Json;
using LifeLevel.Modules.Leaderboard.Application.DTOs;
using LifeLevel.Modules.Leaderboard.Domain;
using LifeLevel.Modules.Leaderboard.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace LifeLevel.Modules.Leaderboard.Application.UseCases;

/// <summary>
/// Ranks players per scope and metric, and pays the rank-up chest: every
/// player you overtake on the global weekly XP board adds a reward to one
/// chest, which opens in one tap.
/// </summary>
public class LeaderboardService(DbContext db, ILeaderboardReadPort scores, IRewardCurrencyPort currency)
{
    public async Task<LeaderboardDto> GetAsync(
        Guid userId, LeaderboardScope scope, LeaderboardMetric metric, CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var weekStart = LeaderboardRules.WeekStart(now);
        await EvaluatePassesAsync(userId, now, ct);

        var pool = await scores.GetPoolAsync(userId, scope, metric, weekStart, ct);
        var ranked = Rank(pool.Entries);
        var mine = ranked.FindIndex(e => e.UserId == userId);

        var entries = ranked.Take(LeaderboardRules.TopCount)
            .Select((e, i) => ToDto(e, i + 1, userId)).ToList();

        LeaderboardMeDto me;
        if (mine < 0)
        {
            me = new LeaderboardMeDto(null, 0, ranked.Count, null, null);
        }
        else
        {
            var next = mine > 0 ? ranked[mine - 1] : null;
            me = new LeaderboardMeDto(
                mine + 1, ranked[mine].Score, ranked.Count,
                next?.Username, next == null ? null : next.Score - ranked[mine].Score);
        }

        return new LeaderboardDto(
            Name(scope), Name(metric), pool.Available, pool.ContextName,
            metric is LeaderboardMetric.Power or LeaderboardMetric.Streak ? null : weekStart.AddDays(7),
            entries, me, await GetChestAsync(userId, ct));
    }

    /// <summary>The chest on your row; checks for new passes first.</summary>
    public async Task<LeaderboardChestDto> GetChestStatusAsync(Guid userId, CancellationToken ct = default)
    {
        await EvaluatePassesAsync(userId, DateTime.UtcNow, ct);
        return await GetChestAsync(userId, ct);
    }

    /// <summary>Claims every stacked pass at once.</summary>
    public async Task<LeaderboardChestOpenedDto> OpenChestAsync(Guid userId, CancellationToken ct = default)
    {
        await using var tx = await BeginTransactionAsync(ct);
        var passes = await db.Set<LeaderboardPass>()
            .Where(p => p.UserId == userId && p.ClaimedAtUtc == null)
            .OrderBy(p => p.CreatedAtUtc)
            .ToListAsync(ct);
        if (passes.Count == 0) return new LeaderboardChestOpenedDto(0, 0, []);

        var now = DateTime.UtcNow;
        foreach (var p in passes) p.ClaimedAtUtc = now;
        await db.SaveChangesAsync(ct);

        var coins = passes.Sum(p => p.Coins);
        var gems = passes.Sum(p => p.Gems);
        if (coins > 0) await currency.AddCoinsAsync(userId, coins, ct);
        if (gems > 0) await currency.AddGemsAsync(userId, gems, ct);
        if (tx != null) await tx.CommitAsync(ct);

        return new LeaderboardChestOpenedDto(coins, gems,
            passes.Select(p => new LeaderboardPassDto(p.PassedUsername, p.PassedAvatarEmoji, p.Coins, p.Gems)).ToList());
    }

    /// <summary>
    /// Compares the players who were just ahead of you last time with the
    /// global weekly XP board now. Anyone from that list who is now behind
    /// you is a pass, paid once per player per week.
    /// </summary>
    internal async Task EvaluatePassesAsync(Guid userId, DateTime now, CancellationToken ct)
    {
        var weekStart = LeaderboardRules.WeekStart(now);
        var pool = await scores.GetPoolAsync(userId, LeaderboardScope.Global, LeaderboardMetric.Xp, weekStart, ct);
        var ranked = Rank(pool.Entries);
        var mine = ranked.FindIndex(e => e.UserId == userId);
        if (mine < 0) return;
        var myScore = ranked[mine].Score;

        var watch = await db.Set<LeaderboardWatch>().FirstOrDefaultAsync(w => w.UserId == userId, ct);
        var passCreated = false;
        if (watch != null && watch.WeekStartUtc == weekStart)
        {
            var wasAhead = JsonSerializer.Deserialize<List<Guid>>(watch.AheadJson) ?? [];
            var nowBehind = ranked.Skip(mine + 1)
                .Select((e, i) => (Entry: e, Rank: mine + 2 + i))
                .Where(x => wasAhead.Contains(x.Entry.UserId) && x.Entry.Score < myScore)
                .ToList();
            if (nowBehind.Count > 0)
            {
                var thisWeek = await db.Set<LeaderboardPass>()
                    .Where(p => p.UserId == userId && p.WeekStartUtc == weekStart)
                    .Select(p => p.PassedUserId)
                    .ToListAsync(ct);
                var budget = LeaderboardRules.MaxPaidPassesPerWeek - thisWeek.Count;
                foreach (var (entry, _) in nowBehind.Where(x => !thisWeek.Contains(x.Entry.UserId)).Take(Math.Max(0, budget)))
                {
                    // Reward by the rank you climbed to: passes near the top pay more.
                    var (coins, gems) = LeaderboardRules.PassReward(mine + 1);
                    db.Set<LeaderboardPass>().Add(new LeaderboardPass
                    {
                        UserId = userId,
                        PassedUserId = entry.UserId,
                        PassedUsername = entry.Username,
                        PassedAvatarEmoji = entry.AvatarEmoji,
                        WeekStartUtc = weekStart,
                        Coins = coins,
                        Gems = gems,
                        CreatedAtUtc = now,
                    });
                    passCreated = true;
                }
            }
        }

        var ahead = ranked.Take(mine).Where(e => e.Score > myScore)
            .TakeLast(LeaderboardRules.WatchDepth).Select(e => e.UserId).ToList();
        var aheadJson = JsonSerializer.Serialize(ahead);
        var watchChanged = watch == null || watch.WeekStartUtc != weekStart || watch.AheadJson != aheadJson;
        if (watch == null)
        {
            watch = new LeaderboardWatch { UserId = userId };
            db.Set<LeaderboardWatch>().Add(watch);
        }
        if (watchChanged)
        {
            watch.WeekStartUtc = weekStart;
            watch.AheadJson = aheadJson;
            watch.UpdatedAtUtc = now;
        }
        if (!watchChanged && !passCreated) return;

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // Another request recorded the same pass or watch first.
            db.ChangeTracker.Clear();
        }
    }

    private async Task<LeaderboardChestDto> GetChestAsync(Guid userId, CancellationToken ct)
    {
        var open = await db.Set<LeaderboardPass>().AsNoTracking()
            .Where(p => p.UserId == userId && p.ClaimedAtUtc == null)
            .Select(p => new { p.Coins, p.Gems })
            .ToListAsync(ct);
        return new LeaderboardChestDto(open.Count, open.Sum(p => p.Coins), open.Sum(p => p.Gems));
    }

    private static List<LeaderboardCandidate> Rank(IEnumerable<LeaderboardCandidate> entries) =>
        entries.OrderByDescending(e => e.Score)
            .ThenByDescending(e => e.Level)
            .ThenBy(e => e.Username, StringComparer.OrdinalIgnoreCase)
            .ToList();

    private static LeaderboardEntryDto ToDto(LeaderboardCandidate e, int rank, Guid viewerId) =>
        new(rank, e.UserId, e.Username, e.AvatarEmoji, e.Level, e.ClassName, e.Score, e.UserId == viewerId);

    public static string Name(LeaderboardScope scope) => scope.ToString().ToLowerInvariant();

    public static string Name(LeaderboardMetric metric) => metric.ToString().ToLowerInvariant();

    private async Task<IDbContextTransaction?> BeginTransactionAsync(CancellationToken ct)
    {
        if (!db.Database.IsRelational()) return null;
        return await db.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable, ct);
    }
}
