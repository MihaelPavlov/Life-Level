namespace LifeLevel.SharedKernel.Calculators;

/// <summary>Pure, deterministic Combat V2 damage formulas.</summary>
public static class BossCombatCalculator
{
    public const int ArmorConstant = 100;
    public const int RecoveryHours = 12;
    public const int CombatVersion = 2;

    public static double Mitigation(int armorOrDefense) =>
        Math.Max(0, armorOrDefense) / (double)(Math.Max(0, armorOrDefense) + ArmorConstant);

    public static int ApplyMitigation(int rawDamage, int armorOrDefense)
    {
        if (rawDamage <= 0) return 0;
        return Math.Max(1, (int)Math.Round(rawDamage * (1.0 - Mitigation(armorOrDefense))));
    }

    public static int ApplyPlayerModifiers(
        int rawWorkoutDamage,
        double damageMultiplier,
        double bossActiveDamagePct)
    {
        if (rawWorkoutDamage <= 0) return 0;
        var powerAdjusted = (int)Math.Round(rawWorkoutDamage * damageMultiplier);
        return (int)Math.Round(powerAdjusted * (1.0 + Math.Max(0, bossActiveDamagePct) / 100.0));
    }
}
