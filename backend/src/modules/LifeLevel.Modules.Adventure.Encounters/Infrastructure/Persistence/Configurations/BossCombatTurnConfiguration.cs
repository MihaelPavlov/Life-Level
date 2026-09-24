using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure.Persistence.Configurations;

public class BossCombatTurnConfiguration : IEntityTypeConfiguration<BossCombatTurn>
{
    public void Configure(EntityTypeBuilder<BossCombatTurn> builder)
    {
        builder.HasKey(x => x.Id);
        builder.HasIndex(x => new { x.UserBossStateId, x.ActivityId }).IsUnique();
        builder.Property(x => x.ActivityType).IsRequired().HasMaxLength(32);
        builder.Property(x => x.SkipReason).HasMaxLength(32);
        builder.HasOne(x => x.UserBossState)
            .WithMany(x => x.CombatTurns)
            .HasForeignKey(x => x.UserBossStateId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
