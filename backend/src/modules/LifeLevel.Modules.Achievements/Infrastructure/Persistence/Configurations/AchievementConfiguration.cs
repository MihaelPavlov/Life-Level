using LifeLevel.Modules.Achievements.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Achievements.Infrastructure.Persistence.Configurations;

public class AchievementConfiguration : IEntityTypeConfiguration<Achievement>
{
    public void Configure(EntityTypeBuilder<Achievement> entity)
    {
        entity.HasKey(a => a.Id);
        entity.Property(a => a.Title).HasMaxLength(200);
        entity.Property(a => a.Description).HasMaxLength(500);
        entity.Property(a => a.Icon).HasMaxLength(10);
        entity.Property(a => a.TargetUnit).HasMaxLength(50);
        entity.Property(a => a.Category).HasConversion<string>();
        entity.Property(a => a.Tier).HasConversion<string>();
        entity.Property(a => a.ConditionType).HasConversion<string>();
    }
}
