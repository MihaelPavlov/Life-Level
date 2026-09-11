using LifeLevel.Modules.Talents.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Talents.Infrastructure.Persistence.Configurations;

public class TalentConfiguration : IEntityTypeConfiguration<Talent>
{
    public void Configure(EntityTypeBuilder<Talent> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Key).HasMaxLength(60);
        entity.Property(x => x.Name).HasMaxLength(80);
        entity.Property(x => x.Description).HasMaxLength(300);
        entity.Property(x => x.IconKey).HasMaxLength(60);
        entity.Property(x => x.Rarity).HasConversion<string>().HasMaxLength(20);
        entity.Property(x => x.EffectType).HasConversion<string>().HasMaxLength(40);
        entity.HasIndex(x => x.Key).IsUnique();
    }
}

public class UserTalentConfiguration : IEntityTypeConfiguration<UserTalent>
{
    public void Configure(EntityTypeBuilder<UserTalent> entity)
    {
        entity.HasKey(x => x.Id);
        entity.HasIndex(x => new { x.UserId, x.TalentId }).IsUnique();
        entity.HasOne<Talent>()
            .WithMany()
            .HasForeignKey(x => x.TalentId)
            .OnDelete(DeleteBehavior.Cascade);
        // Cross-module: UserTalent → User FK configured in AppDbContext
    }
}

public class UserTalentWalletConfiguration : IEntityTypeConfiguration<UserTalentWallet>
{
    public void Configure(EntityTypeBuilder<UserTalentWallet> entity)
    {
        entity.HasKey(x => x.Id);
        entity.HasIndex(x => x.UserId).IsUnique();
        entity.Property(x => x.SecondWindWeekKey).HasMaxLength(10);
        // Cross-module: UserTalentWallet → User FK configured in AppDbContext
    }
}

public class TalentDrawEntryConfiguration : IEntityTypeConfiguration<TalentDrawEntry>
{
    public void Configure(EntityTypeBuilder<TalentDrawEntry> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Kind).HasConversion<string>().HasMaxLength(20);
        entity.HasIndex(x => new { x.UserId, x.DrawnAt });
        // Cross-module: TalentDrawEntry → User FK configured in AppDbContext
    }
}
