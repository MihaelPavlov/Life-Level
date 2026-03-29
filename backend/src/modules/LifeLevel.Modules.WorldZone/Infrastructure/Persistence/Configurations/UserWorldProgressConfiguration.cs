using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class UserWorldProgressConfiguration : IEntityTypeConfiguration<UserWorldProgress>
{
    public void Configure(EntityTypeBuilder<UserWorldProgress> builder)
    {
        builder.HasKey(p => p.Id);
        builder.HasOne(p => p.World)
               .WithMany(w => w.UserProgresses)
               .HasForeignKey(p => p.WorldId)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(p => p.CurrentZone)
               .WithMany()
               .HasForeignKey(p => p.CurrentZoneId)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(p => p.CurrentEdge)
               .WithMany()
               .HasForeignKey(p => p.CurrentEdgeId)
               .IsRequired(false)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(p => p.DestinationZone)
               .WithMany()
               .HasForeignKey(p => p.DestinationZoneId)
               .IsRequired(false)
               .OnDelete(DeleteBehavior.Restrict);
    }
}
