using LifeLevel.Modules.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Identity.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> entity)
    {
        entity.HasKey(u => u.Id);
        entity.HasIndex(u => u.Email).IsUnique();
        entity.HasIndex(u => u.Username).IsUnique();
        entity.Property(u => u.Role).HasConversion<string>();
    }
}
