using LifeLevel.Modules.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Identity.Infrastructure.Persistence.Configurations;

public class UserRingItemConfiguration : IEntityTypeConfiguration<UserRingItem>
{
    public void Configure(EntityTypeBuilder<UserRingItem> entity)
    {
        entity.HasKey(r => r.Id);
        entity.HasOne(r => r.User)
            .WithMany(u => u.RingItems)
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        entity.Property(r => r.ItemType).HasConversion<string>();
    }
}
