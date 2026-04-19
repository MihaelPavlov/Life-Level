namespace LifeLevel.SharedKernel.Ports;

public interface ICharacterXpPort
{
    Task<XpAwardResult> AwardXpAsync(Guid userId, string source, string sourceEmoji, string description, long xp, CancellationToken ct = default);
}

public record XpAwardResult(bool LeveledUp, int PreviousLevel, int NewLevel)
{
    public static readonly XpAwardResult None = new(false, 0, 0);
}
