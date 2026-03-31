using LifeLevel.Modules.Integrations.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Integrations.Infrastructure.Persistence.Configurations;

public class ExternalActivityRecordConfiguration : IEntityTypeConfiguration<ExternalActivityRecord>
{
    public void Configure(EntityTypeBuilder<ExternalActivityRecord> entity)
    {
        entity.HasKey(r => r.Id);
        entity.Property(r => r.Provider).HasMaxLength(50).IsRequired();
        entity.Property(r => r.ExternalId).HasMaxLength(200).IsRequired();
        entity.HasIndex(r => new { r.CharacterId, r.Provider, r.ExternalId }).IsUnique();
        // Cross-module: ExternalActivityRecord → Character FK configured in AppDbContext
    }
}
