using LifeLevel.Modules.Guild.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Guild.Infrastructure.Persistence.Configurations;

public class GuildMemberConfiguration : IEntityTypeConfiguration<GuildMember>
{
    public void Configure(EntityTypeBuilder<GuildMember> entity)
    {
        entity.HasKey(m => m.Id);
        entity.Property(m => m.Role).HasConversion<string>().HasMaxLength(20);
        entity.HasIndex(m => m.UserId).IsUnique();
        entity.HasIndex(m => new { m.GuildId, m.UserId }).IsUnique();
    }
}
