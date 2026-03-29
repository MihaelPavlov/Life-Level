using LifeLevel.Modules.Map.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Map.Infrastructure.Persistence.Configurations;

public class MapEdgeConfiguration : IEntityTypeConfiguration<MapEdge>
{
    public void Configure(EntityTypeBuilder<MapEdge> builder)
    {
        builder.HasKey(e => e.Id);
        builder.HasOne(e => e.FromNode)
               .WithMany(n => n.EdgesFrom)
               .HasForeignKey(e => e.FromNodeId)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(e => e.ToNode)
               .WithMany(n => n.EdgesTo)
               .HasForeignKey(e => e.ToNodeId)
               .OnDelete(DeleteBehavior.Restrict);
    }
}
