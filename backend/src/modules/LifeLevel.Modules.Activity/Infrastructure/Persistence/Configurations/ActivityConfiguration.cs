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
        // Cross-module: Activity → Character FK configured in AppDbContext
    }
}
