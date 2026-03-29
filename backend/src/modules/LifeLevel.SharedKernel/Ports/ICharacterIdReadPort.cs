namespace LifeLevel.SharedKernel.Ports;

public interface ICharacterIdReadPort
{
    Task<Guid?> GetCharacterIdAsync(Guid userId, CancellationToken ct = default);
}
