using LifeLevel.SharedKernel.Calculators;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Api.Application.Adapters;

/// <summary>
/// Composition-root adapter for <see cref="ICharacterCombatStatsReadPort"/> —
/// mirrors <see cref="UserReadPortAdapter"/>'s pattern. Composes ports from
/// three modules (Character, Items, Talents) plus a DbContext-only
/// Encounters port; none of their implementations depend back on
/// Boss/Guild/ActivityBossDamageAdapter, so this introduces no DI cycle.
/// </summary>
internal class CharacterCombatStatsAdapter(
    ICharacterStatsSnapshotReadPort statsSnapshot,
    IGearBonusReadPort gearBonus,
    ITalentBonusReadPort talentBonus,
    IBossDefeatedCountReadPort bossDefeatedCount) : ICharacterCombatStatsReadPort
{
    public async Task<CombatStatsSnapshot> GetCombatStatsAsync(Guid userId, CancellationToken ct = default)
    {
        var stats = await statsSnapshot.GetStatsAsync(userId, ct);
        if (stats is null)
        {
            return new CombatStatsSnapshot(0, 0, 0, 0, 1.0);
        }

        var gear = await gearBonus.GetEquippedBonusesAsync(userId, ct);
        var talents = await talentBonus.GetBonusesAsync(userId, ct);
        var bossesDefeated = await bossDefeatedCount.GetDefeatedCountAsync(userId, ct);

        var effStr = stats.Strength + gear.StrBonus + talents.StrBonus;
        var effEnd = stats.Endurance + gear.EndBonus + talents.EndBonus;
        var effAgi = stats.Agility + gear.AgiBonus + talents.AgiBonus;
        var effFlx = stats.Flexibility + gear.FlxBonus + talents.FlxBonus;
        var effSta = stats.Stamina + gear.StaBonus + talents.StaBonus;

        var attack = CombatStatsCalculator.CalculateAttack(effStr, effAgi, talents.BossDamagePct);
        var defense = CombatStatsCalculator.CalculateDefense(effAgi, effFlx);
        var health = CombatStatsCalculator.CalculateHealth(effSta, effEnd);
        var power = CombatStatsCalculator.CalculatePower(stats.Level, attack, defense, health, bossesDefeated);
        var multiplier = CombatStatsCalculator.CalculateDamageMultiplier(power);

        return new CombatStatsSnapshot(attack, defense, health, power, multiplier);
    }
}
