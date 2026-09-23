namespace LifeLevel.SharedKernel.Ports;

public enum ShopCurrency { Coins, Gems }

public record ShopWalletBalance(long Coins, int Gems);

public interface IShopWalletPort
{
    Task<ShopWalletBalance> GetBalanceAsync(Guid userId, CancellationToken ct = default);
    Task<bool> TrySpendAsync(Guid userId, ShopCurrency currency, int amount, CancellationToken ct = default);
}
