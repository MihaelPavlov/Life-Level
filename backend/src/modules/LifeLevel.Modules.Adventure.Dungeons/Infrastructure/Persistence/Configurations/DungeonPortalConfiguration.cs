using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Dungeons.Infrastructure.Persistence.Configurations;

public class DungeonPortalConfiguration : IEntityTypeConfiguration<DungeonPortal>
{
    public void Configure(EntityTypeBuilder<DungeonPortal> builder)
    {
        builder.HasKey(d => d.Id);
        // NodeId → MapNode is cross-module — configured in AppDbContext
    }
}
