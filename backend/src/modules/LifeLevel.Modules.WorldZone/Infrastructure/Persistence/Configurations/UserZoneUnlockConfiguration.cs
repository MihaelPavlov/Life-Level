using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class UserZoneUnlockConfiguration : IEntityTypeConfiguration<UserZoneUnlock>
{
    public void Configure(EntityTypeBuilder<UserZoneUnlock> builder)
    {
        builder.HasKey(u => new { u.UserId, u.WorldZoneId });
        builder.HasOne(u => u.WorldZone)
               .WithMany(z => z.UnlockedByUsers)
               .HasForeignKey(u => u.WorldZoneId)
               .OnDelete(DeleteBehavior.Restrict);
        builder.HasOne(u => u.UserWorldProgress)
               .WithMany(p => p.UnlockedZones)
               .HasForeignKey(u => u.UserWorldProgressId);
    }
}
