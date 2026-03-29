using LifeLevel.Modules.Map.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Map.Infrastructure.Persistence.Configurations;

public class UserMapProgressConfiguration : IEntityTypeConfiguration<UserMapProgress>
{
    public void Configure(EntityTypeBuilder<UserMapProgress> builder)
    {
        builder.HasKey(p => p.Id);
        builder.HasOne(p => p.CurrentNode)
               .WithMany()
               .HasForeignKey(p => p.CurrentNodeId)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(p => p.CurrentEdge)
               .WithMany()
               .HasForeignKey(p => p.CurrentEdgeId)
               .IsRequired(false)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(p => p.DestinationNode)
               .WithMany()
               .HasForeignKey(p => p.DestinationNodeId)
               .IsRequired(false)
               .OnDelete(DeleteBehavior.Restrict);
        // UserId → User is cross-module — configured in AppDbContext
    }
}
