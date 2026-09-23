using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Items.Application.DTOs;

public record ShopWalletDto(long Coins, int Gems);
public record ShopRefreshDto(int CostCoins, bool CanRefresh, bool Refreshed, string? UnavailableReason);
public record ShopOfferDto(ItemDto Item, ShopCurrency Currency, int Price, bool Owned, bool CanPurchase, string? UnavailableReason);
public record ShopChestDto(string Key, string DisplayName, string Rarity, ShopCurrency Currency, int Price, int RemainingItemCount, bool CanPurchase, string? UnavailableReason);
public record ShopResponse(ShopWalletDto Wallet, DateTime ResetAtUtc, ShopRefreshDto Refresh,
    List<ShopOfferDto> DailyOffers, List<ShopChestDto> Chests, int InventoryCount,
    int MaxInventorySlots, bool RealMoneyComingSoon = true);
public record ShopPurchaseRequest(Guid ClientPurchaseId);
public record ShopPurchaseResult(ShopResponse Shop, ItemDto GrantedItem);
