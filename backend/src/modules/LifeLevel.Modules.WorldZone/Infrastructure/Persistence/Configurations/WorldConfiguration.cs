using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class WorldConfiguration : IEntityTypeConfiguration<World>
{
    public void Configure(EntityTypeBuilder<World> builder)
    {
        builder.HasKey(w => w.Id);
    }
}
