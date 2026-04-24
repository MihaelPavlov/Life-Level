using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure.Persistence.Configurations;

public class BossConfiguration : IEntityTypeConfiguration<Boss>
{
    public void Configure(EntityTypeBuilder<Boss> builder)
    {
        builder.HasKey(b => b.Id);
        // NodeId → MapNode is cross-module — configured in AppDbContext

        // World-zone bridge: nullable column + index, no FK (cross-module soft link).
        builder.Property(b => b.WorldZoneId);
        builder.HasIndex(b => b.WorldZoneId);

        builder.Property(b => b.SuppressExpiry).IsRequired();
    }
}
