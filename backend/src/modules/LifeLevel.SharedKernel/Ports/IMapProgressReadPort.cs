namespace LifeLevel.SharedKernel.Ports;

public interface IMapProgressReadPort
{
    Task<Guid?> GetCurrentNodeIdAsync(Guid userId, CancellationToken ct = default);
}
