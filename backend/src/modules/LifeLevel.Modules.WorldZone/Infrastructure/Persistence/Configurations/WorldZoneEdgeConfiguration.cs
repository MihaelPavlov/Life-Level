using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class WorldZoneEdgeConfiguration : IEntityTypeConfiguration<WorldZoneEdge>
{
    public void Configure(EntityTypeBuilder<WorldZoneEdge> builder)
    {
        builder.HasKey(e => e.Id);
        builder.HasOne(e => e.FromZone)
               .WithMany(z => z.EdgesFrom)
               .HasForeignKey(e => e.FromZoneId)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(e => e.ToZone)
               .WithMany(z => z.EdgesTo)
               .HasForeignKey(e => e.ToZoneId)
               .OnDelete(DeleteBehavior.Restrict);
    }
}
