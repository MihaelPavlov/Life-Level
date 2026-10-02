using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class UserRegionChestClaimConfiguration : IEntityTypeConfiguration<UserRegionChestClaim>
{
    public void Configure(EntityTypeBuilder<UserRegionChestClaim> builder)
    {
        builder.HasKey(x => x.Id);
        builder.HasIndex(x => new { x.UserId, x.RegionId }).IsUnique();
        builder.HasOne<Region>()
            .WithMany()
            .HasForeignKey(x => x.RegionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
