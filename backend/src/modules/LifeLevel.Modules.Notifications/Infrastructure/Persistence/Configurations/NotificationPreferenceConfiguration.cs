using LifeLevel.Modules.Notifications.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Notifications.Infrastructure.Persistence.Configurations;

public class NotificationPreferenceConfiguration : IEntityTypeConfiguration<NotificationPreference>
{
    public void Configure(EntityTypeBuilder<NotificationPreference> entity)
    {
        entity.HasKey(p => p.Id);
        entity.HasIndex(p => p.UserId).IsUnique();
        entity.Property(p => p.PushEnabled).IsRequired();
        entity.Property(p => p.LevelUpEnabled).IsRequired();
        entity.Property(p => p.QuestEnabled).IsRequired();
        entity.Property(p => p.BossEnabled).IsRequired();
        entity.Property(p => p.StreakEnabled).IsRequired();
        entity.Property(p => p.RankEnabled).IsRequired();
        entity.Property(p => p.QuietHoursEnabled).IsRequired();
        entity.Property(p => p.QuietHoursStartUtc).IsRequired();
        entity.Property(p => p.QuietHoursEndUtc).IsRequired();
        entity.Property(p => p.UpdatedAt).IsRequired();
    }
}
