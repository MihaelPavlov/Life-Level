using LifeLevel.Modules.Seasons.Application.DTOs;
using LifeLevel.Modules.Seasons.Domain.Entities;
using LifeLevel.Modules.Seasons.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Seasons.Application.UseCases;

public class SeasonService(
    DbContext db,
    ICharacterXpPort characterXp,
    IStreakShieldPort streakShield,
    ITitleUnlockPort titleUnlock,
    ICharacterIdReadPort characterIdRead,
    IItemRewardGrantPort itemGrant) : ISeasonRolloverPort
{
    // ── Season XP accrual (called by the event handlers) ─────────────────────

    public async Task AddSeasonXpAsync(Guid userId, int amount, CancellationToken ct = default)
    {
        if (amount <= 0) return;

        var season = await GetActiveSeasonAsync(ct);
        if (season == null) return;

        var progress = await GetOrCreateProgressAsync(userId, season.Id, ct);
        progress.SeasonXp += amount;
        progress.CurrentTier = TierFor(progress.SeasonXp, season);
        progress.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    // ── Read model for the mobile Season Track screen ────────────────────────

    public async Task<SeasonTrackResponse> GetTrackAsync(Guid userId, CancellationToken ct = default)
    {
        var season = await GetActiveSeasonAsync(ct);
        if (season == null)
        {
            return new SeasonTrackResponse(
                HasActiveSeason: false, Season: null, XpPerTier: 0, TierCount: 0, MilestoneTier: 0,
                SeasonXp: 0, CurrentTier: 0, XpIntoTier: 0, XpToNextTier: 0,
                HasFounderPass: false, NextReward: null, Tiers: Array.Empty<SeasonTierView>());
        }

        var progress = await GetOrCreateProgressAsync(userId, season.Id, ct);
        var hasPass = await db.Set<UserFounderPass>()
            .AnyAsync(p => p.UserId == userId && p.SeasonId == season.Id, ct);

        var tiers = await db.Set<SeasonRewardTier>()
            .Where(t => t.SeasonId == season.Id)
            .ToListAsync(ct);
        var claims = await db.Set<UserSeasonClaim>()
            .Where(c => c.UserId == userId && c.SeasonId == season.Id)
            .Select(c => new { c.Tier, c.Track })
            .ToListAsync(ct);
        var claimed = claims.Select(c => (c.Tier, c.Track)).ToHashSet();

        var current = progress.CurrentTier;
        var byTier = tiers.ToLookup(t => t.Tier);

        var views = new List<SeasonTierView>(season.TierCount);
        for (var tier = 1; tier <= season.TierCount; tier++)
        {
            var free = byTier[tier].FirstOrDefault(t => t.Track == SeasonTrack.Free);
            var founder = byTier[tier].FirstOrDefault(t => t.Track == SeasonTrack.Founder);
            views.Add(new SeasonTierView(
                Tier: tier,
                IsMilestone: tier == season.MilestoneTier,
                Free: ToView(free, SeasonTrack.Free, tier, current, hasPass, claimed),
                Founder: ToView(founder, SeasonTrack.Founder, tier, current, hasPass, claimed)));
        }

        var pendingTier = current < season.TierCount ? current + 1 : (int?)null;
        NextRewardView? next = null;
        if (pendingTier is int pt)
        {
            var pr = byTier[pt].FirstOrDefault(t => t.Track == SeasonTrack.Free)
                     ?? byTier[pt].FirstOrDefault(t => t.Track == SeasonTrack.Founder);
            if (pr != null) next = new NextRewardView(pt, pr.Label, pr.Track.ToString());
        }

        var xpIntoTier = current >= season.TierCount
            ? 0
            : (int)(progress.SeasonXp - (long)current * season.XpPerTier);
        var xpToNext = current >= season.TierCount ? 0 : Math.Max(0, season.XpPerTier - xpIntoTier);
        var daysLeft = Math.Max(0, (int)Math.Ceiling((season.EndsAt - DateTime.UtcNow).TotalDays));

        return new SeasonTrackResponse(
            HasActiveSeason: true,
            Season: new SeasonHeader(season.Id, season.Number, season.Name, season.Theme,
                season.StartsAt, season.EndsAt, daysLeft),
            XpPerTier: season.XpPerTier,
            TierCount: season.TierCount,
            MilestoneTier: season.MilestoneTier,
            SeasonXp: progress.SeasonXp,
            CurrentTier: current,
            XpIntoTier: Math.Max(0, xpIntoTier),
            XpToNextTier: xpToNext,
            HasFounderPass: hasPass,
            NextReward: next,
            Tiers: views);
    }

    // ── Claim one tile ──────────────────────────────────────────────────────

    /// <exception cref="InvalidOperationException">Tier not reached / already claimed / no season.</exception>
    /// <exception cref="UnauthorizedAccessException">Founder tile without the pass.</exception>
    public async Task<SeasonClaimResult> ClaimTierAsync(
        Guid userId, int tier, SeasonTrack track, bool auto = false, CancellationToken ct = default)
    {
        var season = await GetActiveSeasonAsync(ct)
                     ?? throw new InvalidOperationException("No active season.");
        return await ClaimTierInternalAsync(userId, season, tier, track, auto, ct);
    }

    public async Task<IReadOnlyList<SeasonClaimResult>> ClaimAvailableAsync(
        Guid userId, CancellationToken ct = default)
    {
        var season = await GetActiveSeasonAsync(ct)
                     ?? throw new InvalidOperationException("No active season.");
        var progress = await GetOrCreateProgressAsync(userId, season.Id, ct);
        var hasPass = await db.Set<UserFounderPass>()
            .AnyAsync(p => p.UserId == userId && p.SeasonId == season.Id, ct);
        var rewards = await db.Set<SeasonRewardTier>()
            .Where(r => r.SeasonId == season.Id)
            .OrderBy(r => r.Tier)
            .ThenBy(r => r.Track)
            .ToListAsync(ct);
        var claimed = (await db.Set<UserSeasonClaim>()
                .Where(c => c.UserId == userId && c.SeasonId == season.Id)
                .Select(c => new { c.Tier, c.Track })
                .ToListAsync(ct))
            .Select(c => (c.Tier, c.Track))
            .ToHashSet();

        var results = new List<SeasonClaimResult>();
        while (true)
        {
            var reward = rewards.FirstOrDefault(r =>
                r.Tier <= progress.CurrentTier &&
                !claimed.Contains((r.Tier, r.Track)) &&
                (r.Track != SeasonTrack.Founder || hasPass));
            if (reward == null) break;

            results.Add(await ClaimTierInternalAsync(
                userId, season, reward.Tier, reward.Track, auto: false, ct));
            claimed.Add((reward.Tier, reward.Track));
        }

        if (results.Count == 0)
            throw new InvalidOperationException("No season rewards are ready to claim.");

        return results;
    }

    private async Task<SeasonClaimResult> ClaimTierInternalAsync(
        Guid userId, Season season, int tier, SeasonTrack track, bool auto, CancellationToken ct)
    {
        // Entitlement gate first — Founder rewards are unreachable without the pass,
        // reached or not.
        if (track == SeasonTrack.Founder)
        {
            var hasPass = await db.Set<UserFounderPass>()
                .AnyAsync(p => p.UserId == userId && p.SeasonId == season.Id, ct);
            if (!hasPass)
                throw new UnauthorizedAccessException("Founder Pass required for this reward.");
        }

        var progress = await GetOrCreateProgressAsync(userId, season.Id, ct);
        if (tier > progress.CurrentTier)
            throw new InvalidOperationException("Tier not reached.");

        var alreadyClaimed = await db.Set<UserSeasonClaim>()
            .AnyAsync(c => c.UserId == userId && c.SeasonId == season.Id
                           && c.Tier == tier && c.Track == track, ct);
        if (alreadyClaimed)
            throw new InvalidOperationException("Reward already claimed.");

        var reward = await db.Set<SeasonRewardTier>()
            .FirstOrDefaultAsync(t => t.SeasonId == season.Id && t.Tier == tier && t.Track == track, ct)
            ?? throw new InvalidOperationException("No reward configured for this tile.");

        long xpAwarded = 0;
        var leveledUp = false;
        int? newLevel = null;
        string? grantedItem = null;
        string? grantedTitleKey = null;

        switch (reward.RewardType)
        {
            case SeasonRewardType.Xp:
                var xpRes = await characterXp.AwardXpAsync(
                    userId, "Season", "🎫", $"Season Tier {tier}: {reward.Label}", reward.Amount, ct);
                xpAwarded = reward.Amount;
                leveledUp = xpRes.LeveledUp;
                newLevel = xpRes.LeveledUp ? xpRes.NewLevel : null;
                break;

            case SeasonRewardType.SeasonXp:
                progress.SeasonXp += reward.Amount;
                progress.CurrentTier = TierFor(progress.SeasonXp, season);
                progress.UpdatedAt = DateTime.UtcNow;
                break;

            case SeasonRewardType.Item when reward.RewardRefId is Guid itemId:
                grantedItem = await itemGrant.GrantAsync(userId, itemId, ct) ?? reward.Label;
                break;

            case SeasonRewardType.StreakShield:
                for (var i = 0; i < Math.Max(1, reward.Amount); i++)
                    await streakShield.AddShieldAsync(userId, ct);
                break;

            case SeasonRewardType.Title when !string.IsNullOrWhiteSpace(reward.RewardKey):
                var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
                if (characterId is Guid cid)
                    await titleUnlock.UnlockAsync(cid, reward.RewardKey!, ct);
                grantedTitleKey = reward.RewardKey;
                break;

            case SeasonRewardType.Cosmetic:
                // No backing system yet — the claim row below is the record of it.
                break;
        }

        db.Set<UserSeasonClaim>().Add(new UserSeasonClaim
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            SeasonId = season.Id,
            Tier = tier,
            Track = track,
            ClaimedAt = DateTime.UtcNow,
            WasAutoGranted = auto,
        });
        await db.SaveChangesAsync(ct);

        return new SeasonClaimResult(tier, track.ToString(), reward.Label,
            xpAwarded, leveledUp, newLevel, grantedItem, grantedTitleKey);
    }

    // ── Founder Pass "purchase" (no payment yet) ─────────────────────────────

    public async Task PurchaseFounderPassAsync(Guid userId, CancellationToken ct = default)
    {
        var season = await GetActiveSeasonAsync(ct)
                     ?? throw new InvalidOperationException("No active season.");

        var existing = await db.Set<UserFounderPass>()
            .AnyAsync(p => p.UserId == userId && p.SeasonId == season.Id, ct);
        if (existing) return; // idempotent

        // TODO: gate behind real IAP receipt validation before launch.
        db.Set<UserFounderPass>().Add(new UserFounderPass
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            SeasonId = season.Id,
            AcquiredAt = DateTime.UtcNow,
            Source = FounderPassSource.Purchase,
        });
        await db.SaveChangesAsync(ct);
    }

    // ── Rollover (ISeasonRolloverPort) ──────────────────────────────────────

    public async Task<int> RolloverDueSeasonsAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var due = await db.Set<Season>()
            .Where(s => s.State == SeasonState.Active && s.EndsAt <= now)
            .ToListAsync(ct);

        var closed = 0;
        foreach (var season in due)
        {
            var progresses = await db.Set<UserSeasonProgress>()
                .Where(p => p.SeasonId == season.Id && p.CurrentTier > 0)
                .ToListAsync(ct);

            foreach (var p in progresses)
            {
                var hasPass = await db.Set<UserFounderPass>()
                    .AnyAsync(fp => fp.UserId == p.UserId && fp.SeasonId == season.Id, ct);

                for (var tier = 1; tier <= p.CurrentTier; tier++)
                {
                    await TryAutoClaim(p.UserId, season, tier, SeasonTrack.Free, ct);
                    if (hasPass)
                        await TryAutoClaim(p.UserId, season, tier, SeasonTrack.Founder, ct);
                }
            }

            season.State = SeasonState.Ended;
            closed++;
        }

        if (closed > 0)
            await db.SaveChangesAsync(ct);

        // Promote the next scheduled season whose window has opened.
        var next = await db.Set<Season>()
            .Where(s => s.State == SeasonState.Scheduled && s.StartsAt <= now)
            .OrderBy(s => s.Number)
            .FirstOrDefaultAsync(ct);
        if (next != null && !await db.Set<Season>().AnyAsync(s => s.State == SeasonState.Active, ct))
        {
            next.State = SeasonState.Active;
            await db.SaveChangesAsync(ct);
        }

        return closed;
    }

    private async Task TryAutoClaim(Guid userId, Season season, int tier, SeasonTrack track, CancellationToken ct)
    {
        try
        {
            await ClaimTierInternalAsync(userId, season, tier, track, auto: true, ct);
        }
        catch (InvalidOperationException)
        {
            // already claimed / no reward configured — fine
        }
        catch (UnauthorizedAccessException)
        {
            // no pass — fine
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    public Task<Season?> GetActiveSeasonAsync(CancellationToken ct = default) =>
        db.Set<Season>().FirstOrDefaultAsync(s => s.State == SeasonState.Active, ct);

    private async Task<UserSeasonProgress> GetOrCreateProgressAsync(Guid userId, Guid seasonId, CancellationToken ct)
    {
        var progress = await db.Set<UserSeasonProgress>()
            .FirstOrDefaultAsync(p => p.UserId == userId && p.SeasonId == seasonId, ct);
        if (progress != null) return progress;

        progress = new UserSeasonProgress
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            SeasonId = seasonId,
            SeasonXp = 0,
            CurrentTier = 0,
            UpdatedAt = DateTime.UtcNow,
        };
        db.Set<UserSeasonProgress>().Add(progress);
        await db.SaveChangesAsync(ct);
        return progress;
    }

    private static int TierFor(long seasonXp, Season season) =>
        season.XpPerTier <= 0 ? 0 : (int)Math.Min(season.TierCount, seasonXp / season.XpPerTier);

    private static SeasonRewardView ToView(
        SeasonRewardTier? reward, SeasonTrack track, int tier, int currentTier,
        bool hasPass, HashSet<(int Tier, SeasonTrack Track)> claimed)
    {
        SeasonTileState state;
        if (reward == null)
            state = SeasonTileState.Locked;
        else if (claimed.Contains((tier, track)))
            state = SeasonTileState.Received;
        else if (track == SeasonTrack.Founder && !hasPass)
            state = SeasonTileState.Locked;
        else if (tier <= currentTier)
            state = SeasonTileState.Ready;
        else if (tier == currentTier + 1)
            state = SeasonTileState.Pending;
        else
            state = SeasonTileState.Locked;

        return new SeasonRewardView(
            Type: reward?.RewardType.ToString() ?? "None",
            Label: reward?.Label ?? "—",
            IconKey: reward?.IconKey ?? string.Empty,
            Amount: reward?.Amount ?? 0,
            Rarity: reward?.Rarity,
            State: char.ToLowerInvariant(state.ToString()[0]) + state.ToString()[1..]);
    }
}
