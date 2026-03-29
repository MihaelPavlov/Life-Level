using LifeLevel.Modules.Quest.Domain.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuestEntity = LifeLevel.Modules.Quest.Domain.Entities.Quest;

namespace LifeLevel.Modules.Quest.Infrastructure.Persistence.Configurations;

public class QuestConfiguration : IEntityTypeConfiguration<QuestEntity>
{
    public void Configure(EntityTypeBuilder<QuestEntity> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Type).HasConversion<string>();
        entity.Property(x => x.Category).HasConversion<string>();
        entity.Property(x => x.RequiredActivity).HasConversion<string?>();
        entity.HasData(QuestSeedData.All);
    }
}
