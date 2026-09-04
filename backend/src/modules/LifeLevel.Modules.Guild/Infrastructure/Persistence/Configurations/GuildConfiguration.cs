using LifeLevel.Modules.Guild.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Guild.Infrastructure.Persistence.Configurations;

public class GuildConfiguration : IEntityTypeConfiguration<Guild.Domain.Entities.Guild>
{
    public void Configure(EntityTypeBuilder<Guild.Domain.Entities.Guild> entity)
    {
        entity.HasKey(g => g.Id);
        entity.Property(g => g.Name).HasMaxLength(60).IsRequired();
        entity.Property(g => g.Description).HasMaxLength(240);
        entity.Property(g => g.Icon).HasMaxLength(40);
        entity.HasIndex(g => g.Name);

        entity.HasMany(g => g.Members)
            .WithOne(m => m.Guild)
            .HasForeignKey(m => m.GuildId)
            .OnDelete(DeleteBehavior.Cascade);

        entity.HasMany(g => g.Raids)
            .WithOne(r => r.Guild)
            .HasForeignKey(r => r.GuildId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
