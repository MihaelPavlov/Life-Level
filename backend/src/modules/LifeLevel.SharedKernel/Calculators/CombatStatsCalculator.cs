namespace LifeLevel.SharedKernel.Calculators;

/// <summary>
/// Pure, dependency-free formulas turning a character's effective stats
/// (own stat + equipped gear bonus + talent bonus — the same additive
/// overlay used everywhere else in the app) into the combat stats shown on
/// the Gear page: Attack, Defense, Health, and a single derived Power
/// number. Power then drives <see cref="CalculateDamageMultiplier"/>, the
/// one place this whole formula reaches into actual gameplay (boss/guild
/// raid damage).
///
/// Every constant lives here, named individually, for easy retuning — this
/// is an initial balance pass, not a final one. See
/// docs/obsidian/07 - Development/Plan - Power Score System.md for the
/// original single-Power design this extends (superseded by this file).
/// </summary>
public static class CombatStatsCalculator
{
    // ── Attack: STR (primary damage stat) + AGI (speed/pace) ───────────────
    // Matches the existing per-stat copy in profile_stat_metadata.dart:
    // STR "+Damage vs bosses". Talent BossDamagePct (a permanent passive
    // bonus) is folded in here — see CalculateAttack — so it must NOT also
    // be applied a second time in the boss/guild damage pipeline.
    public const int AttackBase = 10;
    public const double AtkStrWeight = 2.0;
    public const double AtkAgiWeight = 1.0;

    // ── Defense: AGI (dodge chance) + FLX (mitigation/recovery) ────────────
    // Matches AGI "+Dodge chance in raids" / FLX "-Recovery time after boss
    // fights" in the same stat copy.
    public const int DefenseBase = 5;
    public const double DefAgiWeight = 1.0;
    public const double DefFlxWeight = 1.5;

    // ── Health: STA (explicit "+Max HP in raids" perk) + END (sustain) ─────
    public const int HealthBase = 50;
    public const double HpStaWeight = 8.0;
    public const double HpEndWeight = 4.0;

    // ── Power: a weighted combination of Attack/Defense/Health, plus level
    // and a prestige term from bosses defeated. Health is naturally a much
    // bigger number than Attack/Defense, so its weight is scaled down to
    // keep the three contributions comparable.
    public const int PowerBaseFloor = 100;
    public const int PowerLevelWeight = 20;
    public const double PowerAttackWeight = 3.0;
    public const double PowerDefenseWeight = 3.0;
    public const double PowerHealthWeight = 0.6;
    public const int PowerBossWeight = 40;

    public const double MultiplierSlope = 0.0005;
    public const double MaxDamageMultiplier = 4.0;

    /// <summary>
    /// Power at a fresh Level-1 character with the game's starting stats
    /// (0 for all 5 core stats — confirmed via <c>CharacterCreatedHandler</c>,
    /// no explicit initializer), zero gear/talent bonuses, and zero bosses
    /// defeated. The floor <see cref="CalculateDamageMultiplier"/> is
    /// anchored to (multiplier == 1.0 exactly here).
    /// </summary>
    public static readonly int PowerFloor = CalculatePower(
        level: 1,
        attack: CalculateAttack(effStr: 0, effAgi: 0, bossDamagePct: 0),
        defense: CalculateDefense(effAgi: 0, effFlx: 0),
        health: CalculateHealth(effSta: 0, effEnd: 0),
        bossesDefeated: 0);

    public static int CalculateAttack(int effStr, int effAgi, double bossDamagePct)
    {
        var raw = AttackBase + AtkStrWeight * effStr + AtkAgiWeight * effAgi;
        return (int)Math.Round(raw * (1.0 + Math.Max(0, bossDamagePct) / 100.0));
    }

    public static int CalculateDefense(int effAgi, int effFlx) =>
        (int)Math.Round(DefenseBase + DefAgiWeight * effAgi + DefFlxWeight * effFlx);

    public static int CalculateHealth(int effSta, int effEnd) =>
        (int)Math.Round(HealthBase + HpStaWeight * effSta + HpEndWeight * effEnd);

    public static int CalculatePower(int level, int attack, int defense, int health, int bossesDefeated) =>
        (int)Math.Round(
            PowerBaseFloor
            + PowerLevelWeight * level
            + PowerAttackWeight * attack
            + PowerDefenseWeight * defense
            + PowerHealthWeight * health
            + PowerBossWeight * bossesDefeated);

    public static double CalculateDamageMultiplier(int power) =>
        Math.Clamp(1.0 + Math.Max(0, power - PowerFloor) * MultiplierSlope, 1.0, MaxDamageMultiplier);
}
