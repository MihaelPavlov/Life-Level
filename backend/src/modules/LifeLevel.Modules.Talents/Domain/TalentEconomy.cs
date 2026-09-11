using LifeLevel.Modules.Talents.Domain.Enums;
using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.Talents.Domain;

/// <summary>
/// Pure static tuning for the talent economy — earn rates, draw cost/odds, upgrade cost curve.
/// First-pass numbers; the catalog rows themselves are admin-editable, these constants are not
/// (change + redeploy). Mirrors <c>SeasonXpRules</c>.
/// </summary>
public static class TalentEconomy
{
    // ── Currency earned from play ───────────────────────────────────────────

    public static int CoinsForActivity(int durationMinutes) =>
        10 + Math.Clamp(Math.Max(0, durationMinutes) / 6, 0, 30);

    public const int CoinsPerQuestComplete = 15;
    public const int CoinsPerAllDailyQuests = 50;
    public const int CoinsPerBossDefeat = 100;
    public const int CoinsPerLevelUp = 200;

    public const int TokensPerLevelUp = 1;
    public const int TokensPerRankUp = 3;

    // ── Draw ───────────────────────────────────────────────────────────────

    public const int DrawTokenCost = 1;
    public const int DrawCoinCost = 300;

    /// <summary>Chance (0..1) a draw yields a brand-new talent, while un-owned talents remain.</summary>
    public const double NewTalentChance = 0.60;

    /// <summary>Shards granted when a draw yields a duplicate, by the drawn talent's rarity.</summary>
    public static (int Min, int Max) ShardPayout(TalentRarity rarity) => rarity switch
    {
        TalentRarity.Epic => (5, 8),
        TalentRarity.Rare => (8, 12),
        _ => (10, 15),
    };

    // ── Upgrade cost: Lv k → k+1 ───────────────────────────────────────────

    public static int UpgradeShardCost(TalentRarity rarity, int currentLevel)
    {
        var baseCost = 5 + 3 * currentLevel;
        return rarity switch
        {
            TalentRarity.Epic => baseCost * 2,
            TalentRarity.Rare => (int)(baseCost * 1.5),
            _ => baseCost,
        };
    }

    public static int UpgradeCoinCost(TalentRarity rarity, int currentLevel)
    {
        var baseCost = 100 * currentLevel;
        return rarity switch
        {
            TalentRarity.Epic => baseCost * 2,
            TalentRarity.Rare => (int)(baseCost * 1.5),
            _ => baseCost,
        };
    }

    // ── Effect helpers ─────────────────────────────────────────────────────

    public static bool IsCardio(ActivityType t) => t is ActivityType.Running or ActivityType.Cycling
        or ActivityType.Swimming or ActivityType.Hiking or ActivityType.Walking;

    public static bool IsStrengthStyle(ActivityType t) => t is ActivityType.Gym
        or ActivityType.Climbing or ActivityType.Yoga;

    /// <summary>ISO-8601 week key, e.g. "2026-W37" — used for the weekly Second Wind reset.</summary>
    public static string WeekKey(DateTime utc)
    {
        var week = System.Globalization.ISOWeek.GetWeekOfYear(utc);
        var year = System.Globalization.ISOWeek.GetYear(utc);
        return $"{year:D4}-W{week:D2}";
    }
}
