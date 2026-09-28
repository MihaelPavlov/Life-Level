using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Character.Infrastructure.Persistence.Configurations;

public class LevelUpReceiptConfiguration : IEntityTypeConfiguration<LevelUpReceipt>
{
    public void Configure(EntityTypeBuilder<LevelUpReceipt> entity)
    {
        entity.HasKey(r => r.Id);
        entity.Property(r => r.Source).HasMaxLength(64);
        entity.Property(r => r.GrantedItemsJson);
        entity.Property(r => r.BlockedItemsJson);
        entity.Property(r => r.GrantedTitlesJson);
        entity.Property(r => r.AvailableAvatarsJson);
        entity.Property(r => r.AvailableRegionsJson);
        entity.HasIndex(r => new { r.UserId, r.AcknowledgedAt, r.CreatedAt });
    }
}
