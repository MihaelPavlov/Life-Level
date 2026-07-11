using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class TrailEncounterTemplateConfiguration : IEntityTypeConfiguration<TrailEncounterTemplate>
{
    public void Configure(EntityTypeBuilder<TrailEncounterTemplate> builder)
    {
        builder.HasKey(t => t.Id);

        builder.Property(t => t.Type).IsRequired().HasMaxLength(200);
        builder.Property(t => t.Name).IsRequired().HasMaxLength(200);
        builder.Property(t => t.Emoji).IsRequired().HasMaxLength(200);
        builder.Property(t => t.ConfigJson).IsRequired();
        builder.Property(t => t.SpawnChance).IsRequired();
        builder.Property(t => t.IsActive).IsRequired();
        builder.Property(t => t.CreatedAt).IsRequired();

        // FK to Region — cascade delete so templates are removed with the region.
        // Navigation property is not used in queries; FK scalar only.
        builder.HasOne(t => t.Region)
               .WithMany()
               .HasForeignKey(t => t.RegionId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(t => t.RegionId);
    }
}
