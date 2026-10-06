using LifeLevel.Modules.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Identity.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> entity)
    {
        entity.HasKey(u => u.Id);
        entity.HasIndex(u => u.NormalizedEmail).IsUnique();
        entity.HasIndex(u => u.Username).IsUnique();
        entity.Property(u => u.Email).HasMaxLength(320);
        entity.Property(u => u.NormalizedEmail).HasMaxLength(320);
        entity.Property(u => u.PasswordHash).IsRequired(false);
        entity.Property(u => u.Role).HasConversion<string>();
    }
}
