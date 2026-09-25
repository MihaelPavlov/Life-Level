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

    /// <summary>
    /// Crystals are deliberately scarce — Coins already cover high-frequency rewards
    /// (activities, quests), so Crystals only trickle in from occasional milestones.
    /// </summary>
    public const int CrystalsPerBossDefeat = 2;
    public const int CrystalsPerZoneCompletion = 2;
    public const int CrystalsPerRewardClaim = 1;

    // ── Draw ───────────────────────────────────────────────────────────────

    public const int BaseDrawCrystalCost = 1;
    public const int BaseDrawCoinCost = 300;
    private const double DrawGrowthRate = 1.015;
    private const double DrawCoinLinearGrowth = 67.999411685344;
    private const double DrawCoinExponentialGrowth = 43.279658674746;
    private const double DrawCrystalLinearGrowth = 0.053924695724;
    private const double DrawCrystalExponentialGrowth = 5.539796310368;

    /// <summary>
    /// Prices use the number of successful draws already completed. The linear component
    /// keeps early growth predictable while the exponential component becomes meaningful
    /// later. The fitted curve costs 1,675 Coins + 4 Crystals after 20 completed draws and
    /// 8,675 Coins + 35 Crystals after 120 completed draws.
    /// </summary>
    public static int DrawCoinCost(int completedDraws)
    {
        var n = Math.Max(0, completedDraws);
        var raw = BaseDrawCoinCost
            + DrawCoinLinearGrowth * n
            + DrawCoinExponentialGrowth * (Math.Pow(DrawGrowthRate, n) - 1);
        if (!double.IsFinite(raw) || raw >= int.MaxValue) return int.MaxValue;
        return Math.Max(BaseDrawCoinCost,
            (int)Math.Round(raw / 5, MidpointRounding.AwayFromZero) * 5);
    }

    public static int DrawCrystalCost(int completedDraws)
    {
        var n = Math.Max(0, completedDraws);
        var raw = BaseDrawCrystalCost
            + DrawCrystalLinearGrowth * n
            + DrawCrystalExponentialGrowth * (Math.Pow(DrawGrowthRate, n) - 1);
        if (!double.IsFinite(raw) || raw >= int.MaxValue) return int.MaxValue;
        return Math.Max(BaseDrawCrystalCost,
            (int)Math.Round(raw, MidpointRounding.AwayFromZero));
    }

    /// <summary>Chance (0..1) a draw yields a brand-new talent, while un-owned talents remain.</summary>
    public const double NewTalentChance = 0.60;

    /// <summary>
    /// Coins + Crystals refunded when a draw yields a duplicate of an already-maxed talent
    /// (nothing left to level up, by the drawn talent's rarity) — first-pass balancing guess.
    /// A duplicate of a non-maxed talent just levels it up instead; see
    /// <see cref="Application.UseCases.TalentService.DrawAsync"/>.
    /// </summary>
    public static (int Coins, int Crystals) DuplicateRefund(TalentRarity rarity) => rarity switch
    {
        TalentRarity.Epic => (150, 1),
        TalentRarity.Rare => (80, 0),
        _ => (50, 0),
    };

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
