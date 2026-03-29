using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Dungeons.Infrastructure.Persistence.Configurations;

public class DungeonFloorConfiguration : IEntityTypeConfiguration<DungeonFloor>
{
    public void Configure(EntityTypeBuilder<DungeonFloor> builder)
    {
        builder.HasKey(f => f.Id);
        builder.HasOne(f => f.DungeonPortal)
               .WithMany(d => d.Floors)
               .HasForeignKey(f => f.DungeonPortalId);
        builder.Property(f => f.RequiredActivity).HasConversion<string>();
    }
}
