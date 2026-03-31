using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Integrations.Infrastructure.Persistence.Configurations;

public class StravaConnectionConfiguration : IEntityTypeConfiguration<StravaConnection>
{
    public void Configure(EntityTypeBuilder<StravaConnection> entity)
    {
        entity.HasKey(s => s.Id);
        entity.Property(s => s.AthleteName).HasMaxLength(200);
        entity.Property(s => s.AccessToken).HasMaxLength(500);
        entity.Property(s => s.RefreshToken).HasMaxLength(500);
        entity.HasIndex(s => s.StravaAthleteId).IsUnique();
        entity.HasIndex(s => s.UserId);
        // Cross-module: StravaConnection → User FK configured in AppDbContext
    }
}
