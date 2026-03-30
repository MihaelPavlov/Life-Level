using LifeLevel.Modules.Items.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Items.Infrastructure.Persistence.Configurations;

public class CharacterItemConfiguration : IEntityTypeConfiguration<CharacterItem>
{
    public void Configure(EntityTypeBuilder<CharacterItem> entity)
    {
        entity.HasKey(ci => ci.Id);
        entity.HasOne(ci => ci.Item)
            .WithMany()
            .HasForeignKey(ci => ci.ItemId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
