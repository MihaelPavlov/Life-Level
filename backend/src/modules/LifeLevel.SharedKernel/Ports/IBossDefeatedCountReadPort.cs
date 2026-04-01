namespace LifeLevel.SharedKernel.Ports;

public interface IBossDefeatedCountReadPort
{
    Task<int> GetDefeatedCountAsync(Guid userId, CancellationToken ct = default);
}
