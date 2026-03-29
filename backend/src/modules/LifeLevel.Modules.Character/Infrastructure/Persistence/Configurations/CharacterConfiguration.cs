using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Character.Infrastructure.Persistence.Configurations;

public class CharacterConfiguration : IEntityTypeConfiguration<Domain.Entities.Character>
{
    public void Configure(EntityTypeBuilder<Domain.Entities.Character> entity)
    {
        entity.HasKey(c => c.Id);
        entity.HasOne(c => c.Class)
            .WithMany()
            .HasForeignKey(c => c.ClassId)
            .IsRequired(false);
    }
}
