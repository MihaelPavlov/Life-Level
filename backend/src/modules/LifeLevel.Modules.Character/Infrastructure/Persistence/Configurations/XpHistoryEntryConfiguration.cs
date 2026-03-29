using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;
using XpHistoryEntryEntity = LifeLevel.Modules.Character.Domain.Entities.XpHistoryEntry;

namespace LifeLevel.Modules.Character.Infrastructure.Persistence.Configurations;

public class XpHistoryEntryConfiguration : IEntityTypeConfiguration<XpHistoryEntryEntity>
{
    public void Configure(EntityTypeBuilder<XpHistoryEntryEntity> entity)
    {
        entity.HasKey(x => x.Id);
        entity.HasOne<CharacterEntity>()
            .WithMany()
            .HasForeignKey(x => x.CharacterId)
            .OnDelete(DeleteBehavior.Cascade);
        entity.Property(x => x.Source).HasMaxLength(64).IsRequired();
        entity.Property(x => x.SourceEmoji).HasMaxLength(16).IsRequired();
        entity.Property(x => x.Description).HasMaxLength(256).IsRequired();
    }
}
