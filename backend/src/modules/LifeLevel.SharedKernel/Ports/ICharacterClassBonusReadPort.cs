namespace LifeLevel.SharedKernel.Ports;

/// <summary>Stat multipliers from the character's class plus their training trait.</summary>
public record ClassBonusSnapshot(float Str, float End, float Agi, float Flx, float Sta, string? TraitKey)
{
    public static readonly ClassBonusSnapshot Neutral = new(1f, 1f, 1f, 1f, 1f, null);
}

public interface ICharacterClassBonusReadPort
{
    Task<ClassBonusSnapshot> GetClassBonusAsync(Guid userId, CancellationToken ct = default);
}
