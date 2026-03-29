using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuestEntity = LifeLevel.Modules.Quest.Domain.Entities.Quest;
using UserQuestProgressEntity = LifeLevel.Modules.Quest.Domain.Entities.UserQuestProgress;

namespace LifeLevel.Modules.Quest.Infrastructure.Persistence.Configurations;

public class UserQuestProgressConfiguration : IEntityTypeConfiguration<UserQuestProgressEntity>
{
    public void Configure(EntityTypeBuilder<UserQuestProgressEntity> entity)
    {
        entity.HasKey(x => x.Id);
        entity.HasOne(x => x.Quest)
            .WithMany(q => q.UserProgress)
            .HasForeignKey(x => x.QuestId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
