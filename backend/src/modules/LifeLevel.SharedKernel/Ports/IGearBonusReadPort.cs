namespace LifeLevel.SharedKernel.Ports;

public interface IGearBonusReadPort
{
    Task<GearBonuses> GetEquippedBonusesAsync(Guid userId, CancellationToken ct = default);
}

public record GearBonuses(int XpBonusPct, int StrBonus, int EndBonus, int AgiBonus, int FlxBonus, int StaBonus)
{
    public static readonly GearBonuses Empty = new(0, 0, 0, 0, 0, 0);
}
