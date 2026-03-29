using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Dungeons.Infrastructure.Persistence.Configurations;

public class CrossroadsConfiguration : IEntityTypeConfiguration<Crossroads>
{
    public void Configure(EntityTypeBuilder<Crossroads> builder)
    {
        builder.HasKey(c => c.Id);
        // NodeId → MapNode is cross-module — configured in AppDbContext
    }
}
