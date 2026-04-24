using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class WorldZoneConfiguration : IEntityTypeConfiguration<WorldZoneEntity>
{
    public void Configure(EntityTypeBuilder<WorldZoneEntity> builder)
    {
        builder.HasKey(z => z.Id);

        builder.Property(z => z.Name).IsRequired().HasMaxLength(128);
        builder.Property(z => z.Description).HasMaxLength(512);
        builder.Property(z => z.Emoji).IsRequired().HasMaxLength(16);

        builder.Property(z => z.Type)
               .IsRequired()
               .HasConversion<int>();

        // Region is the zone's parent; WorldId lives on Region now.
        builder.HasOne(z => z.Region)
               .WithMany(r => r.Zones)
               .HasForeignKey(z => z.RegionId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(z => new { z.RegionId, z.Tier });

        // Branch → Crossroads: nullable scalar (no nav property; using the id directly
        // keeps seed + DTOs simple). Indexed for branch-lookup queries.
        builder.Property(z => z.BranchOfId);
        builder.HasIndex(z => z.BranchOfId);

        // Chest reward fields: populated only for Chest-type zones.
        builder.Property(z => z.ChestRewardXp);
        builder.Property(z => z.ChestRewardDescription).HasMaxLength(256);

        // Dungeon bonus XP: populated only for Dungeon-type zones.
        builder.Property(z => z.DungeonBonusXp);

        // Boss timer fields: populated only for Boss-type zones. Both nullable
        // so non-boss rows stay null; bridge service falls back to the legacy
        // "no timeout" behavior when they're null.
        builder.Property(z => z.BossTimerDays);
        builder.Property(z => z.BossSuppressExpiry);
    }
}
