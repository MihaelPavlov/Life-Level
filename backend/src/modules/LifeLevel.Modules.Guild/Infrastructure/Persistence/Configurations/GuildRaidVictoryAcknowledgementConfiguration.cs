using LifeLevel.Modules.Guild.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Guild.Infrastructure.Persistence.Configurations;

public class GuildRaidVictoryAcknowledgementConfiguration : IEntityTypeConfiguration<GuildRaidVictoryAcknowledgement>
{
    public void Configure(EntityTypeBuilder<GuildRaidVictoryAcknowledgement> entity)
    {
        entity.HasKey(a => a.Id);
        entity.HasIndex(a => new { a.GuildRaidId, a.UserId }).IsUnique();

        entity.HasOne(a => a.GuildRaid)
            .WithMany()
            .HasForeignKey(a => a.GuildRaidId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
