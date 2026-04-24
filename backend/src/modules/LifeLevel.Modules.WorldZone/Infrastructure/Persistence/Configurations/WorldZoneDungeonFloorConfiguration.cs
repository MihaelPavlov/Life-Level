using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class WorldZoneDungeonFloorConfiguration : IEntityTypeConfiguration<WorldZoneDungeonFloor>
{
    public void Configure(EntityTypeBuilder<WorldZoneDungeonFloor> builder)
    {
        builder.HasKey(f => f.Id);

        builder.Property(f => f.WorldZoneId).IsRequired();
        builder.Property(f => f.Ordinal).IsRequired();
        builder.Property(f => f.Name).IsRequired().HasMaxLength(128);
        builder.Property(f => f.Emoji).IsRequired().HasMaxLength(16);

        builder.Property(f => f.ActivityType).IsRequired().HasConversion<int>();
        builder.Property(f => f.TargetKind).IsRequired().HasConversion<int>();
        builder.Property(f => f.TargetValue).IsRequired();

        builder.HasIndex(f => new { f.WorldZoneId, f.Ordinal }).IsUnique();
    }
}
