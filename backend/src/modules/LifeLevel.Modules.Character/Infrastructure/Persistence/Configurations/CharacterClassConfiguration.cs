using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

using CharacterClassEntity = LifeLevel.Modules.Character.Domain.Entities.CharacterClass;

namespace LifeLevel.Modules.Character.Infrastructure.Persistence.Configurations;

public class CharacterClassConfiguration : IEntityTypeConfiguration<CharacterClassEntity>
{
    public void Configure(EntityTypeBuilder<CharacterClassEntity> entity)
    {
        entity.HasKey(c => c.Id);
        entity.HasIndex(c => c.Name).IsUnique();
        entity.HasData(Domain.Data.CharacterClasses.SeedData);
    }
}
