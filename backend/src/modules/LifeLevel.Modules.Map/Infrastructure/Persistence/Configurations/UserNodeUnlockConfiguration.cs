using LifeLevel.Modules.Map.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Map.Infrastructure.Persistence.Configurations;

public class UserNodeUnlockConfiguration : IEntityTypeConfiguration<UserNodeUnlock>
{
    public void Configure(EntityTypeBuilder<UserNodeUnlock> builder)
    {
        builder.HasKey(u => new { u.UserId, u.MapNodeId });
        builder.HasOne(u => u.MapNode)
               .WithMany()
               .HasForeignKey(u => u.MapNodeId)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(u => u.UserMapProgress)
               .WithMany(p => p.UnlockedNodes)
               .HasForeignKey(u => u.UserMapProgressId);
        // UserId → User is cross-module — configured in AppDbContext
    }
}
