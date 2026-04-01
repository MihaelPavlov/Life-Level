using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Character.Infrastructure.Persistence.Configurations;

public class CharacterTitleConfiguration : IEntityTypeConfiguration<CharacterTitle>
{
    public void Configure(EntityTypeBuilder<CharacterTitle> entity)
    {
        entity.HasKey(ct => ct.Id);
        entity.HasOne(ct => ct.Character)
            .WithMany()
            .HasForeignKey(ct => ct.CharacterId)
            .OnDelete(DeleteBehavior.Cascade);
        entity.HasOne(ct => ct.Title)
            .WithMany()
            .HasForeignKey(ct => ct.TitleId)
            .OnDelete(DeleteBehavior.Restrict);
        entity.HasIndex(ct => new { ct.CharacterId, ct.TitleId }).IsUnique();
    }
}
