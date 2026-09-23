using LifeLevel.Modules.Items.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Items.Infrastructure.Persistence.Configurations;

public class UserShopDailyStateConfiguration : IEntityTypeConfiguration<UserShopDailyState>
{
    public void Configure(EntityTypeBuilder<UserShopDailyState> entity)
    {
        entity.HasKey(x => x.Id);
        entity.HasIndex(x => new { x.UserId, x.RotationDateUtc }).IsUnique();
        entity.Property(x => x.ItemIdsJson).HasMaxLength(512);
    }
}

public class ShopPurchaseConfiguration : IEntityTypeConfiguration<ShopPurchase>
{
    public void Configure(EntityTypeBuilder<ShopPurchase> entity)
    {
        entity.HasKey(x => x.Id);
        entity.HasIndex(x => new { x.UserId, x.ClientPurchaseId }).IsUnique();
        entity.Property(x => x.OfferKey).HasMaxLength(80);
        entity.Property(x => x.Currency).HasConversion<string>().HasMaxLength(16);
    }
}
