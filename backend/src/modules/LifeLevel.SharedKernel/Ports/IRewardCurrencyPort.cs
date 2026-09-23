namespace LifeLevel.SharedKernel.Ports;

public interface IRewardCurrencyPort
{
    Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default);
    Task AddCrystalsAsync(Guid userId, int amount, CancellationToken ct = default);
}
