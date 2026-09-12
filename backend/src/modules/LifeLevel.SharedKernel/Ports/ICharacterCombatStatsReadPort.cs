namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Cross-module read of a character's derived combat stats (see
/// <c>CombatStatsCalculator</c>) — the one thing Boss/Guild need from
/// Character+Items+Talents to scale activity-based damage. Implemented by a
/// composition-root adapter (mirrors <c>IUserReadPort</c>/
/// <c>UserReadPortAdapter</c>) since no single module can own all three
/// dependencies without forming a DI cycle.
/// </summary>
public interface ICharacterCombatStatsReadPort
{
    Task<CombatStatsSnapshot> GetCombatStatsAsync(Guid userId, CancellationToken ct = default);
}

public record CombatStatsSnapshot(int Attack, int Defense, int Health, int Power, double DamageMultiplier);
