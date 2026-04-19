using LifeLevel.Modules.Notifications.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Notifications.Infrastructure.Persistence.Configurations;

public class DeviceTokenConfiguration : IEntityTypeConfiguration<DeviceToken>
{
    public void Configure(EntityTypeBuilder<DeviceToken> entity)
    {
        entity.HasKey(t => t.Id);
        entity.Property(t => t.Token).IsRequired().HasMaxLength(4096);
        entity.Property(t => t.Platform).HasConversion<string>().HasMaxLength(16);
        entity.HasIndex(t => t.Token).IsUnique();
        entity.HasIndex(t => new { t.UserId, t.IsActive });
        // Cross-module FK (DeviceToken.UserId → User) configured in AppDbContext.
    }
}
