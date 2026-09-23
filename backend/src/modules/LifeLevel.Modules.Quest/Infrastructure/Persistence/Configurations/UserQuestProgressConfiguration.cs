using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LifeLevel.Modules.Quest.Domain.Entities;
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

public class TaskRewardMilestoneClaimConfiguration : IEntityTypeConfiguration<TaskRewardMilestoneClaim>
{
    public void Configure(EntityTypeBuilder<TaskRewardMilestoneClaim> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.PeriodType).HasConversion<string>();
        entity.HasIndex(x => new { x.UserId, x.PeriodType, x.PeriodStartUtc, x.Threshold })
            .IsUnique();
    }
}
