using LifeLevel.Modules.Guild.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Guild.Infrastructure.Persistence.Configurations;

public class GuildRaidContributionConfiguration : IEntityTypeConfiguration<GuildRaidContribution>
{
    public void Configure(EntityTypeBuilder<GuildRaidContribution> entity)
    {
        entity.HasKey(c => c.Id);
        entity.HasIndex(c => new { c.GuildRaidId, c.UserId }).IsUnique();
    }
}
