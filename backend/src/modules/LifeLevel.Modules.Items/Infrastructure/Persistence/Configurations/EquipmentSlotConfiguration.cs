using LifeLevel.Modules.Items.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Items.Infrastructure.Persistence.Configurations;

public class EquipmentSlotConfiguration : IEntityTypeConfiguration<EquipmentSlot>
{
    public void Configure(EntityTypeBuilder<EquipmentSlot> entity)
    {
        entity.HasKey(s => s.Id);
        entity.Property(s => s.SlotType).HasConversion<string>();
        entity.HasIndex(s => new { s.CharacterId, s.SlotType }).IsUnique();
        entity.HasOne(s => s.CharacterItem)
            .WithMany()
            .HasForeignKey(s => s.CharacterItemId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);
        // Cross-module FK (CharacterId → Character) is configured in AppDbContext
    }
}
