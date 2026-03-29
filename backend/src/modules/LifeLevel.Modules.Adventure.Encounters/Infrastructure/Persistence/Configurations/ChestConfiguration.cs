using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure.Persistence.Configurations;

public class ChestConfiguration : IEntityTypeConfiguration<Chest>
{
    public void Configure(EntityTypeBuilder<Chest> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Rarity).HasConversion<string>();
        // NodeId → MapNode is cross-module — configured in AppDbContext
    }
}
