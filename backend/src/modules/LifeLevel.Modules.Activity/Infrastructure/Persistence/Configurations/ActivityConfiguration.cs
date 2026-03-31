using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using ActivityEntity = LifeLevel.Modules.Activity.Domain.Entities.Activity;

namespace LifeLevel.Modules.Activity.Infrastructure.Persistence.Configurations;

public class ActivityConfiguration : IEntityTypeConfiguration<ActivityEntity>
{
    public void Configure(EntityTypeBuilder<ActivityEntity> entity)
    {
        entity.HasKey(a => a.Id);
        entity.Property(a => a.Type).HasConversion<string>();
        entity.Property(a => a.ExternalId).HasMaxLength(200);
        // Partial unique index on (CharacterId, ExternalId) configured in AppDbContext
        // (requires relational EF extensions not available in this module)
        // Cross-module: Activity → Character FK configured in AppDbContext
    }
}
