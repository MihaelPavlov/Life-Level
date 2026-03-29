using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class WorldZoneConfiguration : IEntityTypeConfiguration<WorldZoneEntity>
{
    public void Configure(EntityTypeBuilder<WorldZoneEntity> builder)
    {
        builder.HasKey(z => z.Id);
        builder.HasOne(z => z.World)
               .WithMany(w => w.Zones)
               .HasForeignKey(z => z.WorldId)
               .OnDelete(DeleteBehavior.Cascade);
    }
}
