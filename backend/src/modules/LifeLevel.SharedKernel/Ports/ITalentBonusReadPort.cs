using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Aggregated, always-active bonuses from every talent a user owns. Read once per operation by
/// Activity / Boss / Guild / Items / Quest / Streak — the talent analogue of <c>IGearBonusReadPort</c>.
/// </summary>
public interface ITalentBonusReadPort
{
    Task<TalentBonuses> GetBonusesAsync(Guid userId, CancellationToken ct = default);

    /// <summary>
    /// Effective activity-XP multiplier for one workout. The Talents module resolves the
    /// "comeback" window (time since a broken streak) internally; the caller only supplies
    /// whether this is the user's first activity today.
    /// </summary>
    Task<double> GetActivityXpMultiplierAsync(Guid userId, ActivityType type, bool isFirstToday, CancellationToken ct = default);
}

/// <summary>
/// All values are already summed across owned talents (<c>PerLevelValue * Level</c>).
/// Percent fields are whole percentage points (e.g. <c>10</c> = +10%).
/// </summary>
public record TalentBonuses(
    int StrBonus,
    int EndBonus,
    int AgiBonus,
    int FlxBonus,
    int StaBonus,
    double ActivityXpPct,
    double MorningXpPct,
    double CardioXpPct,
    double StrengthStyleXpPct,
    double ComebackXpPct,
    double QuestXpPct,
    double BossDamagePct,
    double BossActiveDamagePct,
    int DropChancePct,
    int SecondWindChargesPerWeek)
{
    public static readonly TalentBonuses Empty =
        new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    /// <summary>XP multiplier for a specific activity, given whether it is the day's first.</summary>
    public double ActivityXpMultiplier(ActivityType type, bool isFirstToday, bool isComeback)
    {
        var pct = ActivityXpPct;
        if (isFirstToday) pct += MorningXpPct;
        if (isComeback) pct += ComebackXpPct;
        if (type is ActivityType.Running or ActivityType.Cycling or ActivityType.Swimming
            or ActivityType.Hiking or ActivityType.Walking) pct += CardioXpPct;
        if (type is ActivityType.Gym or ActivityType.Climbing or ActivityType.Yoga) pct += StrengthStyleXpPct;
        return 1.0 + pct / 100.0;
    }
}
