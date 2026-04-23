using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class RegionConfiguration : IEntityTypeConfiguration<Region>
{
    public void Configure(EntityTypeBuilder<Region> builder)
    {
        builder.HasKey(r => r.Id);

        builder.Property(r => r.Name).IsRequired().HasMaxLength(128);
        builder.Property(r => r.Emoji).IsRequired().HasMaxLength(16);
        builder.Property(r => r.Lore).IsRequired().HasMaxLength(512);
        builder.Property(r => r.BossName).IsRequired().HasMaxLength(128);
        builder.Property(r => r.PinsJson).IsRequired();

        builder.Property(r => r.Theme)
               .IsRequired()
               .HasConversion<string>()
               .HasMaxLength(32);

        builder.Property(r => r.BossStatus)
               .IsRequired()
               .HasConversion<string>()
               .HasMaxLength(16);

        builder.Property(r => r.DefaultStatus)
               .IsRequired()
               .HasConversion<string>()
               .HasMaxLength(16);

        builder.Property(r => r.ChapterIndex).IsRequired();
        builder.Property(r => r.LevelRequirement).IsRequired();

        builder.HasOne(r => r.World)
               .WithMany(w => w.Regions)
               .HasForeignKey(r => r.WorldId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(r => r.Zones)
               .WithOne(z => z.Region)
               .HasForeignKey(z => z.RegionId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasIndex(r => new { r.WorldId, r.Name }).IsUnique();

        // Ignore the convenience record — it's serialized into PinsJson, not a table.
        builder.Ignore(typeof(RegionPin).FullName!);
    }
}
