using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class UserWorldDungeonFloorStateConfiguration : IEntityTypeConfiguration<UserWorldDungeonFloorState>
{
    public void Configure(EntityTypeBuilder<UserWorldDungeonFloorState> builder)
    {
        builder.HasKey(s => s.Id);

        builder.Property(s => s.UserId).IsRequired();
        builder.Property(s => s.FloorId).IsRequired();
        builder.Property(s => s.Status).IsRequired().HasConversion<int>();
        builder.Property(s => s.ProgressValue).IsRequired();

        builder.HasIndex(s => new { s.UserId, s.FloorId }).IsUnique();
    }
}
