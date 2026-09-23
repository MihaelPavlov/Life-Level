using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Items.Domain.Entities;

public class ShopPurchase
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid ClientPurchaseId { get; set; }
    public string OfferKey { get; set; } = string.Empty;
    public Guid GrantedItemId { get; set; }
    public ShopCurrency Currency { get; set; }
    public int Price { get; set; }
    public DateTime PurchasedAtUtc { get; set; }
}
