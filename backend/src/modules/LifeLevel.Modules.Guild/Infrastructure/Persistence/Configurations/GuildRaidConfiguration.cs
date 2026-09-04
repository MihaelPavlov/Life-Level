using LifeLevel.Modules.Guild.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Guild.Infrastructure.Persistence.Configurations;

public class GuildRaidConfiguration : IEntityTypeConfiguration<GuildRaid>
{
    public void Configure(EntityTypeBuilder<GuildRaid> entity)
    {
        entity.HasKey(r => r.Id);
        entity.HasIndex(r => new { r.GuildId, r.IsDefeated, r.IsExpired });

        entity.HasMany(r => r.Contributions)
            .WithOne(c => c.GuildRaid)
            .HasForeignKey(c => c.GuildRaidId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
