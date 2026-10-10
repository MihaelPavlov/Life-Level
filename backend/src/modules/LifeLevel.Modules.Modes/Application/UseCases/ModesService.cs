using System.Security.Cryptography;
using System.Text.Json;
using LifeLevel.Modules.Modes.Application.DTOs;
using LifeLevel.Modules.Modes.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace LifeLevel.Modules.Modes.Application.UseCases;

public class ModesService(
    DbContext db,
    IActivityHistoryReadPort activities,
    ICharacterStatsSnapshotReadPort stats,
    IChestItemRewardPort chestItems,
    IRewardCurrencyPort currency,
    ITalentProfileReadPort profile)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    private static readonly string[] StatKeys = ["str", "end", "agi", "flx", "sta"];
    private static readonly string[] EventKeys = ["collapsedGate", "floodedTunnel", "trapCorridor", "crystalPuzzle", "longPassage"];
    private static readonly Dictionary<string, string> EventStats = new()
    {
        ["collapsedGate"] = "str", ["floodedTunnel"] = "end", ["trapCorridor"] = "agi",
        ["crystalPuzzle"] = "flx", ["longPassage"] = "sta",
    };

    public async Task<ModesOverviewDto> GetOverviewAsync(Guid userId, CancellationToken ct = default)
    {
        var wallet = await profile.GetSummaryAsync(userId, ct);
        return new ModesOverviewDto(
            new ModeWalletDto(wallet.Coins, wallet.Gems, wallet.TalentCrystals),
            await GetBurnChainAsync(userId, ct),
            await GetTreasureDelveAsync(userId, ct));
    }

    public async Task<BurnChainDto> GetBurnChainAsync(Guid userId, CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var run = await db.Set<BurnChainRun>().Where(x => x.UserId == userId)
            .OrderByDescending(x => x.StartedAtUtc).FirstOrDefaultAsync(ct);
        if (run == null || now >= run.EndsAtUtc && run.CollectedAtUtc != null)
            return EmptyBurn();
        return await SynchronizeBurnAsync(run, now, ct);
    }

    public async Task<BurnChainDto> StartBurnChainAsync(Guid userId, CancellationToken ct = default)
    {
        await using var tx = await BeginTransactionAsync(ct);
        var now = DateTime.UtcNow;
        var latest = await db.Set<BurnChainRun>().Where(x => x.UserId == userId)
            .OrderByDescending(x => x.StartedAtUtc).FirstOrDefaultAsync(ct);
        if (latest != null && now < latest.EndsAtUtc)
            throw new ModeRuleException("burn_chain_cooldown", "A Burn Chain window is already active.");

        var run = new BurnChainRun
        {
            UserId = userId,
            StartedAtUtc = now,
            EndsAtUtc = now.AddHours(24),
        };
        db.Set<BurnChainRun>().Add(run);
        await db.SaveChangesAsync(ct);
        if (tx != null) await tx.CommitAsync(ct);
        return ToBurnDto(run, [], "live");
    }

    public async Task<BurnChainDto> AcknowledgeBurnLinksAsync(Guid userId, int count, CancellationToken ct = default)
    {
        var run = await CurrentBurnAsync(userId, ct);
        var dto = await SynchronizeBurnAsync(run, DateTime.UtcNow, ct);
        run.AcknowledgedLinks = Math.Clamp(count, run.AcknowledgedLinks, dto.Links.Count);
        await db.SaveChangesAsync(ct);
        return dto with { AcknowledgedLinks = run.AcknowledgedLinks };
    }

    public async Task<BurnChainDto> CollectBurnChainAsync(Guid userId, CancellationToken ct = default)
    {
        var run = await CurrentBurnAsync(userId, ct);
        var dto = await SynchronizeBurnAsync(run, DateTime.UtcNow, ct);
        if (run.CollectedAtUtc != null) return dto;
        if (run.EndedAtUtc == null)
            throw new ModeRuleException("burn_chain_not_finished", "The Burn Chain is still active.");

        await using var tx = await BeginTransactionAsync(ct);
        await SettleAsync(userId, "BurnChain", run.Id, run.CoinsAwarded, run.TalentCrystalsAwarded, ct);
        run.CollectedAtUtc = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        if (tx != null) await tx.CommitAsync(ct);
        return ToBurnDto(run, Read<List<BurnChainLinkDto>>(run.LinksJson), "cooldown");
    }

    public async Task<TreasureDelveStatusDto> GetTreasureDelveAsync(Guid userId, CancellationToken ct = default)
    {
        await ExpireDelveAsync(userId, ct);
        var now = DateTime.UtcNow;
        var day = UtcDay(now);
        var earned = await RunsEarnedAsync(userId, day, ct);
        var used = await db.Set<TreasureDelveRun>().CountAsync(x => x.UserId == userId && x.EntryDateUtc == day, ct);
        var active = await db.Set<TreasureDelveRun>()
            .Where(x => x.UserId == userId && x.AcknowledgedAtUtc == null)
            .OrderByDescending(x => x.StartedAtUtc).FirstOrDefaultAsync(ct);
        var best = await db.Set<TreasureDelveRun>().Where(x => x.UserId == userId && x.SettledAtUtc != null)
            .Select(x => (int?)x.CoinsAwarded).MaxAsync(ct) ?? 0;
        return new TreasureDelveStatusDto(
            earned, used, Math.Max(0, earned - used), FeaturedStat(day), best,
            day.AddDays(1), active == null ? null : ToDelveDto(active));
    }

    public async Task<DelveRunDto> StartDelveAsync(Guid userId, CancellationToken ct = default)
    {
        await ExpireDelveAsync(userId, ct);
        await using var tx = await BeginTransactionAsync(ct);
        var existing = await db.Set<TreasureDelveRun>()
            .Where(x => x.UserId == userId && x.AcknowledgedAtUtc == null)
            .OrderByDescending(x => x.StartedAtUtc).FirstOrDefaultAsync(ct);
        if (existing != null) return ToDelveDto(existing);

        var now = DateTime.UtcNow;
        var day = UtcDay(now);
        var earned = await RunsEarnedAsync(userId, day, ct);
        var used = await db.Set<TreasureDelveRun>().CountAsync(x => x.UserId == userId && x.EntryDateUtc == day, ct);
        if (used >= earned) throw new ModeRuleException("delve_no_entries", "Complete a qualifying workout to earn a Delve entry.");
        var snapshot = await stats.GetStatsAsync(userId, ct)
            ?? throw new ModeRuleException("character_missing", "Create a character before starting Treasure Delve.");
        var run = new TreasureDelveRun
        {
            UserId = userId, EntryDateUtc = day, StartedAtUtc = now, UpdatedAtUtc = now,
            FeaturedStat = FeaturedStat(day), Strength = snapshot.Strength,
            Endurance = snapshot.Endurance, Agility = snapshot.Agility,
            Flexibility = snapshot.Flexibility, Stamina = snapshot.Stamina,
        };
        run.OptionsJson = Write(GenerateOptions(run));
        db.Set<TreasureDelveRun>().Add(run);
        await db.SaveChangesAsync(ct);
        if (tx != null) await tx.CommitAsync(ct);
        return ToDelveDto(run);
    }

    public async Task<DelveRunDto> ChooseDelvePathAsync(Guid userId, Guid runId, string path, CancellationToken ct = default)
    {
        var run = await DelveRunAsync(userId, runId, ct);
        path = NormalizePath(path);
        if (run.Phase is not ("choosing" or "challenge"))
            throw new ModeRuleException("invalid_phase", "A path can only be selected before the attempt.");
        if (run.Phase == "challenge" && run.ChosenPath == path) return ToDelveDto(run);
        if (!Read<List<DelveOptionDto>>(run.OptionsJson).Any(x => x.Path == path))
            throw new ModeRuleException("invalid_path", "Choose Safe, Treasure, or Cursed.");
        run.ChosenPath = path;
        run.Phase = "challenge";
        run.UpdatedAtUtc = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return ToDelveDto(run);
    }

    public async Task<DelveRunDto> AttemptDelveAsync(Guid userId, Guid runId, CancellationToken ct = default)
    {
        var run = await DelveRunAsync(userId, runId, ct);
        if (run.Phase is "decision" or "result") return ToDelveDto(run);
        RequirePhase(run, "challenge");
        var option = Read<List<DelveOptionDto>>(run.OptionsJson).Single(x => x.Path == run.ChosenPath);
        var success = option.Guaranteed || RandomNumberGenerator.GetInt32(1_000_000) < option.SuccessChance * 1_000_000;
        var history = Read<List<DelveHistoryDto>>(run.HistoryJson);
        string? itemName = null, itemIcon = null, itemRarity = null;

        await using var tx = await BeginTransactionAsync(ct);
        if (success)
        {
            run.RoomsCleared++;
            if (option.Guaranteed) run.SecuredCoins += option.Coins;
            else run.AtRiskCoins += option.Coins;
            if (option.ItemChance > 0 && RandomNumberGenerator.GetInt32(1_000_000) < option.ItemChance * 1_000_000)
            {
                var granted = await chestItems.GrantRandomUnownedAsync(
                    userId, option.Path == "treasure" ? "Common" : "Rare", ct);
                if (granted != null)
                {
                    itemName = granted.Name; itemIcon = granted.Icon; itemRarity = granted.Rarity;
                    var items = Read<List<DelveItemDto>>(run.ItemsJson);
                    items.Add(new DelveItemDto(granted.ItemId, granted.Name, granted.Icon, granted.Rarity, granted.InventoryIconUrl));
                    run.ItemsJson = Write(items);
                }
            }
        }
        history.Add(new DelveHistoryDto(run.Chamber, option.Path, option.Event, success,
            success ? option.Coins : 0, itemName, itemIcon, itemRarity));
        run.HistoryJson = Write(history);
        run.UpdatedAtUtc = DateTime.UtcNow;
        if (!success)
        {
            run.AtRiskCoins = 0;
            await FinishDelveAsync(run, "failed", run.SecuredCoins, ct);
        }
        else if (run.Chamber >= 4)
        {
            await FinishDelveAsync(run, "cleared", run.SecuredCoins + run.AtRiskCoins, ct);
        }
        else run.Phase = "decision";
        await db.SaveChangesAsync(ct);
        if (tx != null) await tx.CommitAsync(ct);
        return ToDelveDto(run);
    }

    public async Task<DelveRunDto> ContinueDelveAsync(Guid userId, Guid runId, CancellationToken ct = default)
    {
        var run = await DelveRunAsync(userId, runId, ct);
        RequirePhase(run, "decision");
        run.Chamber++;
        run.Phase = "choosing";
        run.ChosenPath = null;
        run.OptionsJson = Write(GenerateOptions(run));
        run.UpdatedAtUtc = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return ToDelveDto(run);
    }

    public async Task<DelveRunDto> BankDelveAsync(Guid userId, Guid runId, CancellationToken ct = default)
    {
        var run = await DelveRunAsync(userId, runId, ct);
        if (run.Phase == "result") return ToDelveDto(run);
        if (run.Phase is not ("choosing" or "challenge" or "decision"))
            throw new ModeRuleException("invalid_phase", "This run cannot be banked now.");
        await using var tx = await BeginTransactionAsync(ct);
        await FinishDelveAsync(run, "banked", run.SecuredCoins + run.AtRiskCoins, ct);
        await db.SaveChangesAsync(ct);
        if (tx != null) await tx.CommitAsync(ct);
        return ToDelveDto(run);
    }

    public async Task<DelveRunDto> AcknowledgeDelveAsync(Guid userId, Guid runId, CancellationToken ct = default)
    {
        var run = await DelveRunAsync(userId, runId, ct);
        RequirePhase(run, "result");
        run.AcknowledgedAtUtc ??= DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return ToDelveDto(run);
    }

    public async Task ReconcileExpiredAsync(CancellationToken ct = default)
    {
        var cutoff = UtcDay(DateTime.UtcNow);
        var users = await db.Set<TreasureDelveRun>()
            .Where(x => x.AcknowledgedAtUtc == null && x.SettledAtUtc == null && x.EntryDateUtc < cutoff)
            .Select(x => x.UserId).Distinct().ToListAsync(ct);
        foreach (var user in users) await ExpireDelveAsync(user, ct);

        var expiredBurns = await db.Set<BurnChainRun>()
            .Where(x => x.EndedAtUtc == null && x.EndsAtUtc <= DateTime.UtcNow).ToListAsync(ct);
        foreach (var run in expiredBurns) await SynchronizeBurnAsync(run, DateTime.UtcNow, ct);
    }

    private async Task<BurnChainDto> SynchronizeBurnAsync(BurnChainRun run, DateTime now, CancellationToken ct)
    {
        if (run.EndedAtUtc != null)
        {
            var frozen = Read<List<BurnChainLinkDto>>(run.LinksJson);
            return ToBurnDto(run, frozen, run.CollectedAtUtc == null ? "ended" : "cooldown");
        }
        var records = await activities.ListForUserBetweenAsync(run.UserId, run.StartedAtUtc, run.EndsAtUtc, ct);
        var eligible = records.Where(x => x.LoggedAt >= run.StartedAtUtc && x.LoggedAt < run.EndsAtUtc
                && x.DurationMinutes >= 10 && x.Calories > 0)
            .OrderBy(x => x.LoggedAt).ThenBy(x => x.Id).ToList();
        var links = new List<BurnChainLinkDto>();
        int? bar = null;
        foreach (var a in eligible)
        {
            var kind = bar == null ? "base" : a.Calories > bar ? "beat" : "breaker";
            var multiplier = kind == "beat" ? 2 : 1;
            links.Add(new BurnChainLinkDto(a.Id, a.Type, a.DurationMinutes, a.Calories,
                a.LoggedAt, kind, bar, multiplier, a.Calories / 5 * multiplier));
            if (kind == "breaker")
            {
                FreezeBurn(run, links, a.LoggedAt, "broken");
                await db.SaveChangesAsync(ct);
                return ToBurnDto(run, links, "ended");
            }
            bar = a.Calories;
        }
        if (now >= run.EndsAtUtc)
        {
            FreezeBurn(run, links, run.EndsAtUtc, "timeUp");
            await db.SaveChangesAsync(ct);
            return ToBurnDto(run, links, "ended");
        }
        return ToBurnDto(run, links, "live");
    }

    private static void FreezeBurn(BurnChainRun run, List<BurnChainLinkDto> links, DateTime endedAt, string reason)
    {
        run.EndedAtUtc = endedAt;
        run.EndReason = reason;
        run.LinksJson = Write(links);
        run.CoinsAwarded = links.Sum(x => x.Coins);
        var beats = links.Count(x => x.Kind == "beat");
        run.TalentCrystalsAwarded = beats >= 3 ? 2 : beats >= 1 ? 1 : 0;
    }

    private async Task FinishDelveAsync(TreasureDelveRun run, string reason, int payout, CancellationToken ct)
    {
        if (run.SettledAtUtc != null) return;
        run.Phase = "result";
        run.EndReason = reason;
        run.CoinsAwarded = payout;
        run.TalentCrystalsAwarded = run.RoomsCleared >= 5 ? 2 : run.RoomsCleared >= 3 ? 1 : 0;
        await SettleAsync(run.UserId, "TreasureDelve", run.Id, run.CoinsAwarded, run.TalentCrystalsAwarded, ct);
        run.SettledAtUtc = DateTime.UtcNow;
        run.UpdatedAtUtc = run.SettledAtUtc.Value;
    }

    private async Task SettleAsync(Guid userId, string mode, Guid runId, int coins, int crystals, CancellationToken ct)
    {
        if (await db.Set<ModeRewardSettlement>().AnyAsync(x => x.Mode == mode && x.RunId == runId, ct)) return;
        db.Set<ModeRewardSettlement>().Add(new ModeRewardSettlement
        {
            UserId = userId, Mode = mode, RunId = runId, Coins = coins, TalentCrystals = crystals,
        });
        if (coins > 0) await currency.AddCoinsAsync(userId, coins, ct);
        if (crystals > 0) await currency.AddTalentCrystalsAsync(userId, crystals, ct);
    }

    private async Task ExpireDelveAsync(Guid userId, CancellationToken ct)
    {
        var cutoff = UtcDay(DateTime.UtcNow);
        var run = await db.Set<TreasureDelveRun>().Where(x => x.UserId == userId
                && x.AcknowledgedAtUtc == null && x.SettledAtUtc == null && x.EntryDateUtc < cutoff)
            .OrderByDescending(x => x.StartedAtUtc).FirstOrDefaultAsync(ct);
        if (run == null) return;
        await using var tx = await BeginTransactionAsync(ct);
        await FinishDelveAsync(run, "expired", run.SecuredCoins + run.AtRiskCoins, ct);
        await db.SaveChangesAsync(ct);
        if (tx != null) await tx.CommitAsync(ct);
    }

    private List<DelveOptionDto> GenerateOptions(TreasureDelveRun run)
    {
        var events = EventKeys.OrderBy(_ => RandomNumberGenerator.GetInt32(int.MaxValue)).Take(3).ToArray();
        return [Option(run, "safe", events[0]), Option(run, "treasure", events[1]), Option(run, "cursed", events[2])];
    }

    private static DelveOptionDto Option(TreasureDelveRun run, string path, string eventKey)
    {
        var stat = EventStats[eventKey];
        var boosted = stat == run.FeaturedStat;
        var baseCoins = path == "safe" ? 10 : path == "treasure" ? 20 : 35;
        var coins = (int)Math.Round(baseCoins * Math.Pow(1.5, run.Chamber) * (boosted ? 1.2 : 1));
        var average = Math.Max(5, (run.Strength + run.Endurance + run.Agility + run.Flexibility + run.Stamina) / 5.0);
        var factor = path == "treasure" ? 1.0 : path == "cursed" ? 1.35 : 0;
        var recommended = path == "safe" ? 0 : Math.Clamp((int)Math.Round(average * factor * (1 + .1 * run.Chamber)), 1, 999);
        var value = stat switch { "str" => run.Strength, "end" => run.Endurance, "agi" => run.Agility, "flx" => run.Flexibility, _ => run.Stamina };
        var chance = recommended <= 0 ? 1 : Math.Clamp(.5 + ((value - recommended) / (double)recommended) * 1.2, .1, .95);
        return new DelveOptionDto(path, eventKey, stat, coins, recommended, chance, boosted,
            path == "safe", path == "treasure" ? .25 : path == "cursed" ? .40 : 0);
    }

    private async Task<int> RunsEarnedAsync(Guid userId, DateTime day, CancellationToken ct)
    {
        var records = await activities.ListForUserBetweenAsync(userId, day, day.AddDays(1), ct);
        return Math.Min(3, records.Where(x => x.LoggedAt >= day && x.LoggedAt < day.AddDays(1))
            .Sum(x => x.DurationMinutes >= 45 ? 2 : x.DurationMinutes >= 20 ? 1 : 0));
    }

    private async Task<BurnChainRun> CurrentBurnAsync(Guid userId, CancellationToken ct) =>
        await db.Set<BurnChainRun>().Where(x => x.UserId == userId)
            .OrderByDescending(x => x.StartedAtUtc).FirstOrDefaultAsync(ct)
        ?? throw new ModeRuleException("burn_chain_missing", "Start a Burn Chain first.");

    private async Task<TreasureDelveRun> DelveRunAsync(Guid userId, Guid id, CancellationToken ct) =>
        await db.Set<TreasureDelveRun>().FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, ct)
        ?? throw new KeyNotFoundException("Treasure Delve run not found.");

    private static void RequirePhase(TreasureDelveRun run, string phase)
    {
        if (run.Phase != phase) throw new ModeRuleException("invalid_phase", $"Expected {phase}, but the run is {run.Phase}.");
    }

    private static string NormalizePath(string path) => path.Trim().ToLowerInvariant() switch
    {
        "safe" => "safe", "treasure" => "treasure", "cursed" => "cursed",
        _ => throw new ModeRuleException("invalid_path", "Choose Safe, Treasure, or Cursed."),
    };

    private static string FeaturedStat(DateTime day) => StatKeys[(int)((day - new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalDays % 5 + 5) % 5];
    private static DateTime UtcDay(DateTime value) => new(value.Year, value.Month, value.Day, 0, 0, 0, DateTimeKind.Utc);
    private static T Read<T>(string json) where T : new() => JsonSerializer.Deserialize<T>(json, Json) ?? new T();
    private static string Write<T>(T value) => JsonSerializer.Serialize(value, Json);

    private static BurnChainDto EmptyBurn() => new(null, "idle", null, null, null, [], 0, null, 0, 0, 0, null, null);
    private static BurnChainDto ToBurnDto(BurnChainRun run, IReadOnlyList<BurnChainLinkDto> links, string phase) =>
        new(run.Id, phase, run.StartedAtUtc, run.EndsAtUtc, run.EndReason, links,
            run.AcknowledgedLinks, links.LastOrDefault(x => x.Kind != "breaker")?.Calories,
            links.Sum(x => x.Coins), links.Count(x => x.Kind == "beat"), run.TalentCrystalsAwarded,
            run.CollectedAtUtc, phase == "cooldown" ? run.EndsAtUtc : null);

    private static DelveRunDto ToDelveDto(TreasureDelveRun run) =>
        new(run.Id, run.Phase, run.EndReason, run.Chamber, run.FeaturedStat,
            run.SecuredCoins, run.AtRiskCoins, run.RoomsCleared, run.ChosenPath,
            Read<List<DelveOptionDto>>(run.OptionsJson), Read<List<DelveHistoryDto>>(run.HistoryJson),
            Read<List<DelveItemDto>>(run.ItemsJson), run.CoinsAwarded, run.TalentCrystalsAwarded,
            run.StartedAtUtc, run.SettledAtUtc);

    private async Task<IDbContextTransaction?> BeginTransactionAsync(CancellationToken ct)
    {
        if (!db.Database.IsRelational() || db.Database.CurrentTransaction is not null) return null;
        return await db.Database.BeginTransactionAsync(
            System.Data.IsolationLevel.Serializable, ct);
    }
}
