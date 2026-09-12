namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// A character's level and 5 core stats, with no gear/talent overlay
/// applied — the raw inputs <see cref="ICharacterCombatStatsReadPort"/>
/// composes with <c>GearBonuses</c>/<c>TalentBonuses</c> to derive combat
/// stats. Implemented directly by <c>CharacterService</c>.
/// </summary>
public interface ICharacterStatsSnapshotReadPort
{
    Task<CharacterStatsSnapshot?> GetStatsAsync(Guid userId, CancellationToken ct = default);
}

public record CharacterStatsSnapshot(
    int Level,
    int Strength,
    int Endurance,
    int Agility,
    int Flexibility,
    int Stamina);
