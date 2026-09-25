using LifeLevel.Modules.Talents.Application.DTOs;
using LifeLevel.Modules.Talents.Domain;
using LifeLevel.Modules.Talents.Domain.Entities;
using LifeLevel.Modules.Talents.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using System.Collections.Concurrent;
using System.Data;

namespace LifeLevel.Modules.Talents.Application.UseCases;

/// <summary>
/// Owns the talent economy: earning currency, drawing talents (a duplicate draw levels the
/// talent up directly — there's no separate manual upgrade action), and exposing the aggregated
/// always-active bonuses that other modules read.
/// </summary>
/// <remarks>
/// Deliberately depends on nothing but <see cref="DbContext"/> — it is itself the implementation
/// of several SharedKernel ports that Streak / Items / Activity / Guild / Quest consume, so taking
/// any of their ports here would create a DI cycle. Streak-shield grants (Shield Craft) are handed
/// back to <c>TalentsController</c> to apply via <c>IStreakShieldPort</c>.
/// </remarks>
public class TalentService(DbContext db)
    : ITalentBonusReadPort, ITalentProfileReadPort, ITalentStreakAssistPort, IRewardCurrencyPort, IShopWalletPort
{
    private static readonly Random Rng = Random.Shared;
    private static readonly ConcurrentDictionary<Guid, SemaphoreSlim> DrawLocks = new();

    // ── ITalentBonusReadPort ───────────────────────────────────────────────

    public async Task<TalentBonuses> GetBonusesAsync(Guid userId, CancellationToken ct = default)
    {
        var rows = await (
            from ut in db.Set<UserTalent>().Where(x => x.UserId == userId)
            join t in db.Set<Talent>() on ut.TalentId equals t.Id
            where t.IsActive
            select new { t.EffectType, t.PerLevelValue, ut.Level }).ToListAsync(ct);

        if (rows.Count == 0) return TalentBonuses.Empty;

        int str = 0, end = 0, agi = 0, flx = 0, sta = 0, drop = 0, secondWind = 0;
        double actXp = 0, morningXp = 0, cardioXp = 0, strXp = 0, comebackXp = 0, questXp = 0,
            bossDmg = 0, bossActiveDmg = 0;

        foreach (var r in rows)
        {
            var v = r.PerLevelValue * r.Level;
            switch (r.EffectType)
            {
                case TalentEffectType.StatStrength: str += (int)Math.Round(v); break;
                case TalentEffectType.StatEndurance: end += (int)Math.Round(v); break;
                case TalentEffectType.StatAgility: agi += (int)Math.Round(v); break;
                case TalentEffectType.StatFlexibility: flx += (int)Math.Round(v); break;
                case TalentEffectType.StatStamina: sta += (int)Math.Round(v); break;
                case TalentEffectType.ActivityXpPct: actXp += v; break;
                case TalentEffectType.MorningXpPct: morningXp += v; break;
                case TalentEffectType.CardioXpPct: cardioXp += v; break;
                case TalentEffectType.StrengthStyleXpPct: strXp += v; break;
                case TalentEffectType.ComebackXpPct: comebackXp += v; break;
                case TalentEffectType.QuestXpPct: questXp += v; break;
                case TalentEffectType.BossDamagePct: bossDmg += v; break;
                case TalentEffectType.BossActiveDamagePct: bossActiveDmg += v; break;
                case TalentEffectType.DropChancePct: drop += (int)Math.Round(v); break;
                case TalentEffectType.SecondWind: secondWind += (int)Math.Floor(v / 2.0); break;
                case TalentEffectType.ShieldPerLevel: break; // one-time grant on level-up, not a passive
            }
        }

        return new TalentBonuses(str, end, agi, flx, sta, actXp, morningXp, cardioXp, strXp,
            comebackXp, questXp, bossDmg, bossActiveDmg, drop, secondWind);
    }

    public async Task<double> GetActivityXpMultiplierAsync(
        Guid userId, LifeLevel.SharedKernel.Enums.ActivityType type, bool isFirstToday, CancellationToken ct = default)
    {
        var bonuses = await GetBonusesAsync(userId, ct);
        var wallet = await db.Set<UserTalentWallet>()
            .FirstOrDefaultAsync(w => w.UserId == userId, ct);
        var isComeback = wallet?.LastStreakBrokenAt is DateTime brokenAt
            && DateTime.UtcNow - brokenAt <= TimeSpan.FromHours(24);
        return bonuses.ActivityXpMultiplier(type, isFirstToday, isComeback);
    }

    // ── ITalentProfileReadPort ─────────────────────────────────────────────

    public async Task<TalentSummaryDto> GetSummaryAsync(Guid userId, CancellationToken ct = default)
    {
        var catalogCount = await db.Set<Talent>().CountAsync(t => t.IsActive, ct);
        var owned = await db.Set<UserTalent>().Where(x => x.UserId == userId)
            .Select(x => x.Level).ToListAsync(ct);
        var wallet = await db.Set<UserTalentWallet>()
            .FirstOrDefaultAsync(w => w.UserId == userId, ct);
        var bonuses = await GetBonusesAsync(userId, ct);

        return new TalentSummaryDto(
            OwnedCount: owned.Count,
            CatalogCount: catalogCount,
            TotalLevels: owned.Sum(),
            Coins: wallet?.Coins ?? 0,
            Crystals: wallet?.Crystals ?? 0,
            StrBonus: bonuses.StrBonus,
            EndBonus: bonuses.EndBonus,
            AgiBonus: bonuses.AgiBonus,
            FlxBonus: bonuses.FlxBonus,
            StaBonus: bonuses.StaBonus,
            EffectLines: EffectLines(bonuses));
    }

    private static IReadOnlyList<string> EffectLines(TalentBonuses b)
    {
        var lines = new List<string>();
        void Stat(string n, int v) { if (v != 0) lines.Add($"+{v} {n}"); }
        void Pct(string n, double v) { if (v != 0) lines.Add($"+{v:0.#}% {n}"); }
        Stat("STR", b.StrBonus); Stat("END", b.EndBonus); Stat("AGI", b.AgiBonus);
        Stat("FLX", b.FlxBonus); Stat("STA", b.StaBonus);
        Pct("workout XP", b.ActivityXpPct);
        Pct("first-workout XP", b.MorningXpPct);
        Pct("cardio XP", b.CardioXpPct);
        Pct("strength-style XP", b.StrengthStyleXpPct);
        Pct("comeback XP", b.ComebackXpPct);
        Pct("quest XP", b.QuestXpPct);
        Pct("boss damage", b.BossDamagePct);
        Pct("boss damage (active)", b.BossActiveDamagePct);
        if (b.DropChancePct != 0) lines.Add($"+{b.DropChancePct} drop chance");
        if (b.SecondWindChargesPerWeek != 0) lines.Add($"{b.SecondWindChargesPerWeek}× streak auto-save / week");
        return lines;
    }

    // ── ITalentStreakAssistPort ────────────────────────────────────────────

    public async Task<bool> TryConsumeSecondWindAsync(Guid userId, DateTime dayUtc, CancellationToken ct = default)
    {
        var charges = (await GetBonusesAsync(userId, ct)).SecondWindChargesPerWeek;
        if (charges <= 0) return false;

        var wallet = await GetOrCreateWalletAsync(userId, ct);
        var weekKey = TalentEconomy.WeekKey(dayUtc);
        if (wallet.SecondWindWeekKey != weekKey)
        {
            wallet.SecondWindWeekKey = weekKey;
            wallet.SecondWindUsedThisWeek = 0;
        }
        if (wallet.SecondWindUsedThisWeek >= charges) return false;

        wallet.SecondWindUsedThisWeek++;
        wallet.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return true;
    }

    // ── Currency credit (called by event handlers) ─────────────────────────

    public async Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default)
    {
        if (amount <= 0) return;
        var wallet = await GetOrCreateWalletAsync(userId, ct);
        wallet.Coins += amount;
        wallet.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    public async Task AddCrystalsAsync(Guid userId, int amount, CancellationToken ct = default)
    {
        if (amount <= 0) return;
        var wallet = await GetOrCreateWalletAsync(userId, ct);
        wallet.Crystals += amount;
        wallet.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    public async Task<ShopWalletBalance> GetBalanceAsync(Guid userId, CancellationToken ct = default)
    {
        var wallet = await GetOrCreateWalletAsync(userId, ct);
        return new ShopWalletBalance(wallet.Coins, wallet.Crystals);
    }

    public async Task<bool> TrySpendAsync(
        Guid userId, ShopCurrency currency, int amount, CancellationToken ct = default)
    {
        if (amount < 0) throw new ArgumentOutOfRangeException(nameof(amount));
        var wallet = await GetOrCreateWalletAsync(userId, ct);
        if (db.Database.IsRelational())
        {
            var updated = currency == ShopCurrency.Coins
                ? await db.Set<UserTalentWallet>()
                    .Where(x => x.UserId == userId && x.Coins >= amount)
                    .ExecuteUpdateAsync(setters => setters
                        .SetProperty(x => x.Coins, x => x.Coins - amount)
                        .SetProperty(x => x.UpdatedAt, DateTime.UtcNow), ct)
                : await db.Set<UserTalentWallet>()
                    .Where(x => x.UserId == userId && x.Crystals >= amount)
                    .ExecuteUpdateAsync(setters => setters
                        .SetProperty(x => x.Crystals, x => x.Crystals - amount)
                        .SetProperty(x => x.UpdatedAt, DateTime.UtcNow), ct);
            if (updated == 1) await db.Entry(wallet).ReloadAsync(ct);
            return updated == 1;
        }
        if (currency == ShopCurrency.Coins)
        {
            if (wallet.Coins < amount) return false;
            wallet.Coins -= amount;
        }
        else
        {
            if (wallet.Crystals < amount) return false;
            wallet.Crystals -= amount;
        }
        wallet.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return true;
    }

    public async Task MarkStreakBrokenAsync(Guid userId, CancellationToken ct = default)
    {
        var wallet = await GetOrCreateWalletAsync(userId, ct);
        wallet.LastStreakBrokenAt = DateTime.UtcNow;
        wallet.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    // ── Mobile read model ─────────────────────────────────────────────────

    public async Task<TalentScreenResponse> GetScreenAsync(Guid userId, CancellationToken ct = default)
    {
        var catalog = await db.Set<Talent>().Where(t => t.IsActive)
            .OrderBy(t => t.SortOrder).ToListAsync(ct);
        var owned = await db.Set<UserTalent>().Where(x => x.UserId == userId)
            .ToDictionaryAsync(x => x.TalentId, ct);
        var wallet = await GetOrCreateWalletAsync(userId, ct);

        var views = catalog.Select(t => ToView(t, owned.GetValueOrDefault(t.Id))).ToList();
        var activeOwnedCount = catalog.Count(t => owned.ContainsKey(t.Id));
        var walletView = new TalentWalletView(wallet.Coins, wallet.Crystals, activeOwnedCount, catalog.Count);
        var talentPoints = catalog.Sum(t => Math.Clamp(
            owned.GetValueOrDefault(t.Id)?.Level ?? 0, 0, Math.Max(0, t.MaxLevel)));
        var maxTalentPoints = catalog.Sum(t => Math.Max(0, t.MaxLevel));
        var collectionComplete = maxTalentPoints > 0 && talentPoints >= maxTalentPoints;
        var drawCount = await db.Set<TalentDrawEntry>().CountAsync(x => x.UserId == userId, ct);
        var drawCrystalCost = TalentEconomy.DrawCrystalCost(drawCount);
        var drawCoinCost = TalentEconomy.DrawCoinCost(drawCount);

        return new TalentScreenResponse(
            Wallet: walletView,
            DrawCount: drawCount,
            DrawCrystalCost: drawCrystalCost,
            DrawCoinCost: drawCoinCost,
            CanDraw: !collectionComplete && catalog.Count > 0 &&
                wallet.Crystals >= drawCrystalCost && wallet.Coins >= drawCoinCost,
            CollectionComplete: collectionComplete,
            Talents: views);
    }

    // ── Draw ──────────────────────────────────────────────────────────────

    /// <exception cref="InvalidOperationException">Not enough currency.</exception>
    public async Task<TalentDrawResult> DrawAsync(Guid userId, CancellationToken ct = default)
    {
        var drawLock = DrawLocks.GetOrAdd(userId, static _ => new SemaphoreSlim(1, 1));
        await drawLock.WaitAsync(ct);
        try
        {
            return await DrawInternalAsync(userId, ct);
        }
        finally
        {
            drawLock.Release();
        }
    }

    private async Task<TalentDrawResult> DrawInternalAsync(Guid userId, CancellationToken ct)
    {
        IDbContextTransaction? transaction = null;
        if (db.Database.IsRelational())
            transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        await using var transactionScope = transaction;

        var wallet = await GetOrCreateWalletAsync(userId, ct);
        var catalog = await db.Set<Talent>().Where(t => t.IsActive).ToListAsync(ct);
        var catalogById = catalog.ToDictionary(t => t.Id);
        var owned = (await db.Set<UserTalent>().Where(x => x.UserId == userId).ToListAsync(ct))
            .Where(x => catalogById.ContainsKey(x.TalentId))
            .ToList();
        var ownedIds = owned.Select(o => o.TalentId).ToHashSet();
        var unowned = catalog.Where(t => !ownedIds.Contains(t.Id)).ToList();
        var talentPoints = owned
            .Where(o => catalogById.ContainsKey(o.TalentId))
            .Sum(o => Math.Clamp(o.Level, 0, Math.Max(0, catalogById[o.TalentId].MaxLevel)));
        var maxTalentPoints = catalog.Sum(t => Math.Max(0, t.MaxLevel));

        if (catalog.Count == 0)
            throw new InvalidOperationException("No talent cards are currently available.");
        if (maxTalentPoints > 0 && talentPoints >= maxTalentPoints)
            throw new InvalidOperationException("Your talent collection is complete.");

        var drawCount = await db.Set<TalentDrawEntry>().CountAsync(x => x.UserId == userId, ct);
        var drawCrystalCost = TalentEconomy.DrawCrystalCost(drawCount);
        var drawCoinCost = TalentEconomy.DrawCoinCost(drawCount);
        if (wallet.Crystals < drawCrystalCost || wallet.Coins < drawCoinCost)
            throw new InvalidOperationException(
                $"Not enough currency. This draw costs {drawCoinCost} Coins and {drawCrystalCost} Crystals.");

        wallet.Crystals -= drawCrystalCost;
        wallet.Coins -= drawCoinCost;
        wallet.UpdatedAt = DateTime.UtcNow;

        var giveNew = unowned.Count > 0 && (owned.Count == 0 || Rng.NextDouble() < TalentEconomy.NewTalentChance);

        TalentDrawKind kind;
        Talent talent;
        int crystalsAwarded = 0;
        UserTalent userTalent;
        var shieldsGranted = 0;

        if (giveNew)
        {
            talent = WeightedPick(unowned, t => Math.Max(1, t.DrawWeight));
            userTalent = new UserTalent
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                TalentId = talent.Id,
                Level = 1,
                UnlockedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
            };
            db.Set<UserTalent>().Add(userTalent);
            kind = TalentDrawKind.NewTalent;

            // Shield Craft grants a shield on each level reached (Lv.1 counts) — applied by the controller.
            if (talent.EffectType == TalentEffectType.ShieldPerLevel)
                shieldsGranted = 1;
        }
        else
        {
            userTalent = owned[Rng.Next(owned.Count)];
            talent = catalog.First(t => t.Id == userTalent.TalentId);
            kind = TalentDrawKind.Duplicate;

            // A duplicate levels the talent up for free (the draw's own cost already paid for
            // it) — no separate upgrade action. Only refund Coins/Crystals when there's nothing
            // left to level (already maxed), so the draw isn't wasted.
            if (userTalent.Level < talent.MaxLevel)
            {
                userTalent.Level++;
                if (talent.EffectType == TalentEffectType.ShieldPerLevel)
                    shieldsGranted = 1;
            }
            else
            {
                var (coinsRefund, crystalsRefund) = TalentEconomy.DuplicateRefund(talent.Rarity);
                wallet.Coins += coinsRefund;
                wallet.Crystals += crystalsRefund;
                crystalsAwarded = crystalsRefund;
            }
            userTalent.UpdatedAt = DateTime.UtcNow;
        }

        db.Set<TalentDrawEntry>().Add(new TalentDrawEntry
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DrawnAt = DateTime.UtcNow,
            Kind = kind,
            TalentId = talent.Id,
            CrystalsAwarded = crystalsAwarded,
            DrawNumber = drawCount + 1,
            CoinsSpent = drawCoinCost,
            CrystalsSpent = drawCrystalCost,
        });

        await db.SaveChangesAsync(ct);
        if (transaction != null) await transaction.CommitAsync(ct);

        var walletView = new TalentWalletView(wallet.Coins, wallet.Crystals,
            ownedIds.Count + (giveNew ? 1 : 0), catalog.Count);
        var view = ToView(talent, userTalent);

        return new TalentDrawResult(
            Kind: char.ToLowerInvariant(kind.ToString()[0]) + kind.ToString()[1..],
            IsNew: giveNew,
            Talent: view,
            CrystalsAwarded: crystalsAwarded,
            ShieldsGranted: shieldsGranted,
            Wallet: walletView);
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private async Task<UserTalentWallet> GetOrCreateWalletAsync(Guid userId, CancellationToken ct)
    {
        var wallet = await db.Set<UserTalentWallet>().FirstOrDefaultAsync(w => w.UserId == userId, ct);
        if (wallet != null) return wallet;

        wallet = new UserTalentWallet { Id = Guid.NewGuid(), UserId = userId, UpdatedAt = DateTime.UtcNow };
        db.Set<UserTalentWallet>().Add(wallet);
        await db.SaveChangesAsync(ct);
        return wallet;
    }

    private static TalentView ToView(Talent t, UserTalent? ut)
    {
        var owned = ut != null;
        var level = ut?.Level ?? 0;
        var state = owned ? TalentTileState.Owned : TalentTileState.Locked;

        return new TalentView(
            Key: t.Key,
            Name: t.Name,
            Description: t.Description,
            IconKey: t.IconKey,
            Rarity: t.Rarity.ToString(),
            MaxLevel: t.MaxLevel,
            Owned: owned,
            Level: level,
            State: char.ToLowerInvariant(state.ToString()[0]) + state.ToString()[1..],
            EffectText: EffectText(t, Math.Max(1, level)));
    }

    private static string EffectText(Talent t, int level)
    {
        var v = t.PerLevelValue * level;
        return t.EffectType switch
        {
            TalentEffectType.StatStrength => $"+{(int)Math.Round(v)} effective STR",
            TalentEffectType.StatEndurance => $"+{(int)Math.Round(v)} effective END",
            TalentEffectType.StatAgility => $"+{(int)Math.Round(v)} effective AGI",
            TalentEffectType.StatFlexibility => $"+{(int)Math.Round(v)} effective FLX",
            TalentEffectType.StatStamina => $"+{(int)Math.Round(v)} effective STA",
            TalentEffectType.ActivityXpPct => $"+{v:0.#}% XP from every workout",
            TalentEffectType.MorningXpPct => $"+{v:0.#}% XP on your first workout each day",
            TalentEffectType.CardioXpPct => $"+{v:0.#}% XP from running / cycling / swimming / hiking",
            TalentEffectType.StrengthStyleXpPct => $"+{v:0.#}% XP from gym / climbing / yoga",
            TalentEffectType.ComebackXpPct => $"+{v:0.#}% XP on your first workout after a broken streak",
            TalentEffectType.QuestXpPct => $"+{v:0.#}% quest reward XP",
            TalentEffectType.BossDamagePct => $"+{v:0.#}% boss damage from every workout",
            TalentEffectType.BossActiveDamagePct => $"+{v:0.#}% extra boss damage while a boss is active",
            TalentEffectType.DropChancePct => $"+{(int)Math.Round(v)} item drop chance",
            TalentEffectType.SecondWind => $"Auto-save a missed streak day {(int)Math.Floor(v / 2.0)}× per week",
            TalentEffectType.ShieldPerLevel => $"+1 streak shield each level (Lv.{level})",
            _ => t.Description,
        };
    }

    private static T WeightedPick<T>(IReadOnlyList<T> items, Func<T, int> weight)
    {
        var total = items.Sum(weight);
        var roll = Rng.Next(total);
        var cum = 0;
        foreach (var item in items)
        {
            cum += weight(item);
            if (roll < cum) return item;
        }
        return items[^1];
    }
}
