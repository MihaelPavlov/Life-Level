using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Dungeons.Infrastructure.Persistence.Configurations;

public class CrossroadsPathConfiguration : IEntityTypeConfiguration<CrossroadsPath>
{
    public void Configure(EntityTypeBuilder<CrossroadsPath> builder)
    {
        builder.HasKey(p => p.Id);
        builder.HasOne(p => p.Crossroads)
               .WithMany(c => c.Paths)
               .HasForeignKey(p => p.CrossroadsId);
        builder.Property(p => p.Difficulty).HasConversion<string>();
        // LeadsToNodeId → MapNode is cross-module — configured in AppDbContext
    }
}
