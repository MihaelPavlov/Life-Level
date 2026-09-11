using LifeLevel.Modules.Talents.Application.DTOs;
using LifeLevel.Modules.Talents.Domain;
using LifeLevel.Modules.Talents.Domain.Entities;
using LifeLevel.Modules.Talents.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Talents.Application.UseCases;

/// <summary>
/// Owns the talent economy: earning currency, drawing/upgrading talents, and exposing the
/// aggregated always-active bonuses that other modules read.
/// </summary>
/// <remarks>
/// Deliberately depends on nothing but <see cref="DbContext"/> — it is itself the implementation
/// of several SharedKernel ports that Streak / Items / Activity / Guild / Quest consume, so taking
/// any of their ports here would create a DI cycle. Streak-shield grants (Shield Craft) are handed
/// back to <c>TalentsController</c> to apply via <c>IStreakShieldPort</c>.
/// </remarks>
public class TalentService(DbContext db)
    : ITalentBonusReadPort, ITalentProfileReadPort, ITalentStreakAssistPort
{
    private static readonly Random Rng = Random.Shared;

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
            Tokens: wallet?.Tokens ?? 0,
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

    public async Task AddTokensAsync(Guid userId, int amount, CancellationToken ct = default)
    {
        if (amount <= 0) return;
        var wallet = await GetOrCreateWalletAsync(userId, ct);
        wallet.Tokens += amount;
        wallet.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
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

        var views = catalog.Select(t => ToView(t, owned.GetValueOrDefault(t.Id), wallet)).ToList();
        var walletView = new TalentWalletView(wallet.Coins, wallet.Tokens, owned.Count, catalog.Count);

        return new TalentScreenResponse(
            Wallet: walletView,
            DrawTokenCost: TalentEconomy.DrawTokenCost,
            DrawCoinCost: TalentEconomy.DrawCoinCost,
            CanDraw: wallet.Tokens >= TalentEconomy.DrawTokenCost && wallet.Coins >= TalentEconomy.DrawCoinCost,
            Talents: views);
    }

    // ── Draw ──────────────────────────────────────────────────────────────

    /// <exception cref="InvalidOperationException">Not enough currency.</exception>
    public async Task<TalentDrawResult> DrawAsync(Guid userId, CancellationToken ct = default)
    {
        var wallet = await GetOrCreateWalletAsync(userId, ct);
        if (wallet.Tokens < TalentEconomy.DrawTokenCost || wallet.Coins < TalentEconomy.DrawCoinCost)
            throw new InvalidOperationException("Not enough currency to draw a talent card.");

        wallet.Tokens -= TalentEconomy.DrawTokenCost;
        wallet.Coins -= TalentEconomy.DrawCoinCost;
        wallet.UpdatedAt = DateTime.UtcNow;

        var catalog = await db.Set<Talent>().Where(t => t.IsActive).ToListAsync(ct);
        var owned = await db.Set<UserTalent>().Where(x => x.UserId == userId).ToListAsync(ct);
        var ownedIds = owned.Select(o => o.TalentId).ToHashSet();
        var unowned = catalog.Where(t => !ownedIds.Contains(t.Id)).ToList();

        var giveNew = unowned.Count > 0 && (owned.Count == 0 || Rng.NextDouble() < TalentEconomy.NewTalentChance);

        TalentDrawKind kind;
        Talent talent;
        int shardsAwarded = 0;
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
                Shards = 0,
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
            var (min, max) = TalentEconomy.ShardPayout(talent.Rarity);
            shardsAwarded = Rng.Next(min, max + 1);
            userTalent.Shards += shardsAwarded;
            userTalent.UpdatedAt = DateTime.UtcNow;
            kind = TalentDrawKind.Shards;
        }

        db.Set<TalentDrawEntry>().Add(new TalentDrawEntry
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DrawnAt = DateTime.UtcNow,
            Kind = kind,
            TalentId = talent.Id,
            ShardsAwarded = shardsAwarded,
        });

        await db.SaveChangesAsync(ct);

        var walletView = new TalentWalletView(wallet.Coins, wallet.Tokens,
            ownedIds.Count + (giveNew ? 1 : 0), catalog.Count);
        var view = ToView(talent, userTalent, wallet);

        return new TalentDrawResult(
            Kind: char.ToLowerInvariant(kind.ToString()[0]) + kind.ToString()[1..],
            IsNew: giveNew,
            Talent: view,
            ShardsAwarded: shardsAwarded,
            ShieldsGranted: shieldsGranted,
            Wallet: walletView);
    }

    // ── Upgrade ───────────────────────────────────────────────────────────

    /// <exception cref="InvalidOperationException">Unknown/unowned talent, maxed, or not enough shards/coins.</exception>
    public async Task<TalentUpgradeResult> UpgradeAsync(Guid userId, string key, CancellationToken ct = default)
    {
        var talent = await db.Set<Talent>().FirstOrDefaultAsync(t => t.Key == key && t.IsActive, ct)
            ?? throw new InvalidOperationException("Unknown talent.");

        var userTalent = await db.Set<UserTalent>()
            .FirstOrDefaultAsync(x => x.UserId == userId && x.TalentId == talent.Id, ct)
            ?? throw new InvalidOperationException("You do not own this talent.");

        if (userTalent.Level >= talent.MaxLevel)
            throw new InvalidOperationException("Talent is already at max level.");

        var shardCost = TalentEconomy.UpgradeShardCost(talent.Rarity, userTalent.Level);
        var coinCost = TalentEconomy.UpgradeCoinCost(talent.Rarity, userTalent.Level);

        var wallet = await GetOrCreateWalletAsync(userId, ct);
        if (userTalent.Shards < shardCost || wallet.Coins < coinCost)
            throw new InvalidOperationException("Not enough shards or coins to upgrade.");

        userTalent.Shards -= shardCost;
        wallet.Coins -= coinCost;
        userTalent.Level++;
        userTalent.UpdatedAt = DateTime.UtcNow;
        wallet.UpdatedAt = DateTime.UtcNow;

        // Shield Craft grants a shield on each level reached — applied by the controller.
        var shieldsGranted = talent.EffectType == TalentEffectType.ShieldPerLevel ? 1 : 0;

        await db.SaveChangesAsync(ct);

        var ownedCount = await db.Set<UserTalent>().CountAsync(x => x.UserId == userId, ct);
        var catalogCount = await db.Set<Talent>().CountAsync(t => t.IsActive, ct);
        var walletView = new TalentWalletView(wallet.Coins, wallet.Tokens, ownedCount, catalogCount);

        return new TalentUpgradeResult(
            Talent: ToView(talent, userTalent, wallet),
            NewLevel: userTalent.Level,
            EffectText: EffectText(talent, userTalent.Level),
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

    private static TalentView ToView(Talent t, UserTalent? ut, UserTalentWallet wallet)
    {
        var owned = ut != null;
        var level = ut?.Level ?? 0;
        var shards = ut?.Shards ?? 0;

        int? upShard = null, upCoin = null;
        var canUpgrade = false;
        if (owned && level < t.MaxLevel)
        {
            upShard = TalentEconomy.UpgradeShardCost(t.Rarity, level);
            upCoin = TalentEconomy.UpgradeCoinCost(t.Rarity, level);
            canUpgrade = shards >= upShard && wallet.Coins >= upCoin;
        }

        var state = !owned ? TalentTileState.Locked
            : canUpgrade ? TalentTileState.Upgradeable
            : TalentTileState.Owned;

        return new TalentView(
            Key: t.Key,
            Name: t.Name,
            Description: t.Description,
            IconKey: t.IconKey,
            Rarity: t.Rarity.ToString(),
            MaxLevel: t.MaxLevel,
            Owned: owned,
            Level: level,
            Shards: shards,
            State: char.ToLowerInvariant(state.ToString()[0]) + state.ToString()[1..],
            EffectText: EffectText(t, Math.Max(1, level)),
            UpgradeShardCost: upShard,
            UpgradeCoinCost: upCoin,
            CanUpgrade: canUpgrade);
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
