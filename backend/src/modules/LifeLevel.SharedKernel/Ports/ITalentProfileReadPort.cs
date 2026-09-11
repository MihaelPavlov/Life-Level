namespace LifeLevel.SharedKernel.Ports;

/// <summary>
/// Compact talent summary for the character profile payload. Kept separate from
/// <c>ITalentBonusReadPort</c> so the Character module never depends on the Talents module —
/// <c>CharacterController</c> enriches its response with this, exactly like <c>GearBonuses</c>.
/// </summary>
public interface ITalentProfileReadPort
{
    Task<TalentSummaryDto> GetSummaryAsync(Guid userId, CancellationToken ct = default);
}

public record TalentSummaryDto(
    int OwnedCount,
    int CatalogCount,
    int TotalLevels,
    long Coins,
    int Tokens,
    int StrBonus,
    int EndBonus,
    int AgiBonus,
    int FlxBonus,
    int StaBonus,
    IReadOnlyList<string> EffectLines)
{
    public static readonly TalentSummaryDto Empty =
        new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Array.Empty<string>());
}
