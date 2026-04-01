using LifeLevel.Modules.Achievements.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Achievements.Infrastructure.Persistence.Configurations;

public class UserAchievementConfiguration : IEntityTypeConfiguration<UserAchievement>
{
    public void Configure(EntityTypeBuilder<UserAchievement> entity)
    {
        entity.HasKey(u => u.Id);
        entity.HasOne(u => u.Achievement)
            .WithMany()
            .HasForeignKey(u => u.AchievementId)
            .OnDelete(DeleteBehavior.Cascade);
        entity.HasIndex(u => new { u.UserId, u.AchievementId }).IsUnique();
    }
}
