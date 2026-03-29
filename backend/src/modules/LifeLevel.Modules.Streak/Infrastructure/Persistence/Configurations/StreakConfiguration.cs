using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using StreakEntity = LifeLevel.Modules.Streak.Domain.Entities.Streak;

namespace LifeLevel.Modules.Streak.Infrastructure.Persistence.Configurations;

public class StreakConfiguration : IEntityTypeConfiguration<StreakEntity>
{
    public void Configure(EntityTypeBuilder<StreakEntity> entity)
    {
        entity.HasKey(x => x.Id);
        // Cross-module FK to User — configured in AppDbContext
    }
}
