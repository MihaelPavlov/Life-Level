using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class UserWorldDungeonStateConfiguration : IEntityTypeConfiguration<UserWorldDungeonState>
{
    public void Configure(EntityTypeBuilder<UserWorldDungeonState> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.UserId).IsRequired();
        builder.Property(s => s.WorldZoneId).IsRequired();
        builder.Property(s => s.Status).IsRequired().HasConversion<int>();
        builder.Property(s => s.CurrentFloorOrdinal).IsRequired();

        builder.HasIndex(s => new { s.UserId, s.WorldZoneId }).IsUnique();
    }
}
