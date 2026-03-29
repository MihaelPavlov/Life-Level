namespace LifeLevel.SharedKernel.Ports;

public interface ICharacterLevelReadPort
{
    Task<int> GetLevelAsync(Guid userId, CancellationToken ct = default);
}
