using LifeLevel.Modules.Items.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Items.Infrastructure.Persistence.Configurations;

public class ItemConfiguration : IEntityTypeConfiguration<Item>
{
    public void Configure(EntityTypeBuilder<Item> entity)
    {
        entity.HasKey(i => i.Id);
        entity.Property(i => i.Rarity).HasConversion<string>();
        entity.Property(i => i.Category).HasConversion<string>().HasMaxLength(30);
        entity.Property(i => i.SlotType).HasConversion<string>();
        entity.Property(i => i.Name).HasMaxLength(100);
        entity.Property(i => i.Description).HasMaxLength(500);
        entity.Property(i => i.Icon).HasMaxLength(10);
    }
}
