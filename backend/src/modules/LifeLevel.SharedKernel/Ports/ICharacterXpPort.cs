namespace LifeLevel.SharedKernel.Ports;

public interface ICharacterXpPort
{
    Task AwardXpAsync(Guid userId, string source, string sourceEmoji, string description, long xp, CancellationToken ct = default);
}
