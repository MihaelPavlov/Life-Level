using LifeLevel.Modules.Notifications.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Notifications.Infrastructure.Persistence.Configurations;

public class NotificationLogConfiguration : IEntityTypeConfiguration<NotificationLog>
{
    public void Configure(EntityTypeBuilder<NotificationLog> entity)
    {
        entity.HasKey(l => l.Id);
        entity.Property(l => l.Category).IsRequired().HasMaxLength(64);
        entity.Property(l => l.Title).IsRequired().HasMaxLength(256);
        entity.Property(l => l.Body).IsRequired().HasMaxLength(1024);
        entity.Property(l => l.Outcome).HasConversion<string>().HasMaxLength(32);
        entity.Property(l => l.ErrorMessage).HasMaxLength(1024);
        // Composite index for the daily-cap count query: (UserId, SentAt).
        entity.HasIndex(l => new { l.UserId, l.SentAt });
        // Cross-module FK (NotificationLog.UserId → User) configured in AppDbContext.
    }
}
