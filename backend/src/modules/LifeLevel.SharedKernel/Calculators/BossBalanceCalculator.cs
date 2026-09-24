namespace LifeLevel.SharedKernel.Calculators;

/// <summary>
/// Canonical world-boss tuning model. It balances each chapter against a
/// conservative, ungeared player at that region's entry level and a median
/// raw workout hit of 250 damage.
/// </summary>
public static class BossBalanceCalculator
{
    public const int MedianRawWorkoutDamage = 250;

    public sealed record Profile(
        int MaxHp,
        int Armor,
        int CounterattackDamage,
        int TargetTurns,
        int TargetHitsToDefeatPlayer,
        int ExpectedDamagePerTurn,
        int ExpectedPlayerHealth,
        int ExpectedPlayerDefense,
        double ExpectedDamageMultiplier);

    public static Profile ForChapter(int chapter, int level)
    {
        chapter = Math.Max(1, chapter);
        level = Math.Max(1, level);

        // Conservative earned-stat distribution; equipment and talents are
        // deliberately excluded from the baseline so obtaining either always
        // feels like an advantage rather than a requirement.
        var str = (int)Math.Round(level * 0.5);
        var agi = (int)Math.Round(level * 0.6);
        var end = (int)Math.Round(level * 0.7);
        var flx = (int)Math.Round(level * 0.3);
        var sta = (int)Math.Round(level * 0.5);
        var previousBossVictories = chapter - 1;

        var attack = CombatStatsCalculator.CalculateAttack(str, agi, 0);
        var defense = CombatStatsCalculator.CalculateDefense(agi, flx);
        var health = CombatStatsCalculator.CalculateHealth(sta, end);
        var power = CombatStatsCalculator.CalculatePower(
            level, attack, defense, health, previousBossVictories);
        var multiplier = CombatStatsCalculator.CalculateDamageMultiplier(power);

        var armor = 10 + 5 * (chapter - 1);
        var targetTurns = chapter <= 4 ? 8 : chapter <= 10 ? 10 : 12;
        var targetHits = chapter <= 4 ? 8 : chapter <= 10 ? 7 : 6;
        var modifiedHit = BossCombatCalculator.ApplyPlayerModifiers(
            MedianRawWorkoutDamage, multiplier, 0);
        var expectedHit = BossCombatCalculator.ApplyMitigation(modifiedHit, armor);
        var maxHp = Math.Max(1, expectedHit * targetTurns);

        // Invert the player's mitigation so the boss defeats the baseline
        // profile in the configured number of surviving counterattacks.
        var desiredTaken = Math.Max(1, (int)Math.Ceiling(health / (double)targetHits));
        var counterattack = Math.Max(1, (int)Math.Round(
            desiredTaken * (defense + BossCombatCalculator.ArmorConstant)
            / (double)BossCombatCalculator.ArmorConstant));

        return new Profile(
            maxHp,
            armor,
            counterattack,
            targetTurns,
            targetHits,
            expectedHit,
            health,
            defense,
            multiplier);
    }
}
