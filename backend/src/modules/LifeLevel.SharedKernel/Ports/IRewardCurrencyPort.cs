namespace LifeLevel.SharedKernel.Ports;

public interface IRewardCurrencyPort
{
    Task AddCoinsAsync(Guid userId, int amount, CancellationToken ct = default);
    Task AddGemsAsync(Guid userId, int amount, CancellationToken ct = default);
    Task AddTalentCrystalsAsync(Guid userId, int amount, CancellationToken ct = default);
}
