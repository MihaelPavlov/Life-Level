using LifeLevel.Modules.Map.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Map.Infrastructure.Persistence.Configurations;

public class MapNodeConfiguration : IEntityTypeConfiguration<MapNode>
{
    public void Configure(EntityTypeBuilder<MapNode> builder)
    {
        builder.HasKey(n => n.Id);
        builder.Property(n => n.Type).HasConversion<string>();
        builder.Property(n => n.Region).HasConversion<string>();
        // WorldZoneId FK is cross-module — configured in AppDbContext
    }
}
