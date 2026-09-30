using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Character.Infrastructure.Persistence.Configurations;

public class CharacterUnlockConfiguration : IEntityTypeConfiguration<CharacterUnlock>
{
    public void Configure(EntityTypeBuilder<CharacterUnlock> entity)
    {
        entity.HasKey(u => u.Id);
        entity.Property(u => u.Key).HasMaxLength(32).IsRequired();
        entity.HasIndex(u => new { u.UserId, u.Key }).IsUnique();
    }
}
