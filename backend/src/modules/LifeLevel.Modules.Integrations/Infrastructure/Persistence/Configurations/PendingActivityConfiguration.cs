using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Integrations.Infrastructure.Persistence.Configurations;

public class PendingActivityConfiguration : IEntityTypeConfiguration<PendingActivity>
{
    public void Configure(EntityTypeBuilder<PendingActivity> entity)
    {
        entity.HasKey(p => p.Id);
        entity.Property(p => p.Provider).HasMaxLength(50).IsRequired();
        entity.Property(p => p.ExternalId).HasMaxLength(200).IsRequired();
        entity.Property(p => p.ActivityType).HasMaxLength(50).IsRequired();
        entity.HasIndex(p => new { p.UserId, p.Provider, p.ExternalId }).IsUnique();
        entity.HasIndex(p => new { p.UserId, p.Status });
        // Cross-module: PendingActivity → User FK configured in AppDbContext
    }
}
