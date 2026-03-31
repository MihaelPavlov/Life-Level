using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Integrations.Infrastructure.Persistence.Configurations;

public class GarminConnectionConfiguration : IEntityTypeConfiguration<GarminConnection>
{
    public void Configure(EntityTypeBuilder<GarminConnection> entity)
    {
        entity.HasKey(g => g.Id);
        entity.Property(g => g.GarminUserId).HasMaxLength(200);
        entity.Property(g => g.DisplayName).HasMaxLength(200);
        entity.Property(g => g.AccessToken).HasMaxLength(500);
        entity.Property(g => g.RefreshToken).HasMaxLength(500);
        entity.HasIndex(g => g.GarminUserId).IsUnique();
        entity.HasIndex(g => g.UserId);
        // Cross-module: GarminConnection → User FK configured in AppDbContext
    }
}
