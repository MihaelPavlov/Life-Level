using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class UserWorldChestStateConfiguration : IEntityTypeConfiguration<UserWorldChestState>
{
    public void Configure(EntityTypeBuilder<UserWorldChestState> builder)
    {
        builder.HasKey(c => c.Id);

        builder.Property(c => c.UserId).IsRequired();
        builder.Property(c => c.WorldZoneId).IsRequired();
        builder.Property(c => c.OpenedAt).IsRequired();

        // One row per user per chest zone — re-opening is rejected at the service layer.
        builder.HasIndex(c => new { c.UserId, c.WorldZoneId }).IsUnique();
    }
}
