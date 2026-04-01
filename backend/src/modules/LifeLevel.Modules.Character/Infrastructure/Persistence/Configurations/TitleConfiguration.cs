using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Character.Infrastructure.Persistence.Configurations;

public class TitleConfiguration : IEntityTypeConfiguration<Title>
{
    public void Configure(EntityTypeBuilder<Title> entity)
    {
        entity.HasKey(t => t.Id);
        entity.Property(t => t.Name).IsRequired().HasMaxLength(100);
        entity.Property(t => t.Emoji).HasMaxLength(10);
        entity.Property(t => t.UnlockCondition).HasMaxLength(200);
        entity.Property(t => t.UnlockCriteria).IsRequired().HasMaxLength(200);
    }
}
