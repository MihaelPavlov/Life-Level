using LifeLevel.Modules.Seasons.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Seasons.Infrastructure.Persistence.Configurations;

public class SeasonConfiguration : IEntityTypeConfiguration<Season>
{
    public void Configure(EntityTypeBuilder<Season> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Name).HasMaxLength(120);
        entity.Property(x => x.Theme).HasMaxLength(40);
        entity.Property(x => x.State).HasConversion<string>().HasMaxLength(20);
        entity.HasMany(x => x.Tiers)
            .WithOne(t => t.Season!)
            .HasForeignKey(t => t.SeasonId)
            .OnDelete(DeleteBehavior.Cascade);
        entity.HasIndex(x => x.State);
    }
}

public class SeasonRewardTierConfiguration : IEntityTypeConfiguration<SeasonRewardTier>
{
    public void Configure(EntityTypeBuilder<SeasonRewardTier> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Track).HasConversion<string>().HasMaxLength(20);
        entity.Property(x => x.RewardType).HasConversion<string>().HasMaxLength(30);
        entity.Property(x => x.Label).HasMaxLength(120);
        entity.Property(x => x.IconKey).HasMaxLength(60);
        entity.Property(x => x.RewardKey).HasMaxLength(60);
        entity.Property(x => x.Rarity).HasMaxLength(20);
        entity.HasIndex(x => new { x.SeasonId, x.Tier, x.Track }).IsUnique();
    }
}

public class UserSeasonProgressConfiguration : IEntityTypeConfiguration<UserSeasonProgress>
{
    public void Configure(EntityTypeBuilder<UserSeasonProgress> entity)
    {
        entity.HasKey(x => x.Id);
        entity.HasIndex(x => new { x.UserId, x.SeasonId }).IsUnique();
        // Cross-module: UserSeasonProgress → User FK configured in AppDbContext
    }
}

public class UserSeasonClaimConfiguration : IEntityTypeConfiguration<UserSeasonClaim>
{
    public void Configure(EntityTypeBuilder<UserSeasonClaim> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Track).HasConversion<string>().HasMaxLength(20);
        entity.HasIndex(x => new { x.UserId, x.SeasonId, x.Tier, x.Track }).IsUnique();
        // Cross-module: UserSeasonClaim → User FK configured in AppDbContext
    }
}

public class UserFounderPassConfiguration : IEntityTypeConfiguration<UserFounderPass>
{
    public void Configure(EntityTypeBuilder<UserFounderPass> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Source).HasConversion<string>().HasMaxLength(20);
        entity.HasIndex(x => new { x.UserId, x.SeasonId }).IsUnique();
        // Cross-module: UserFounderPass → User FK configured in AppDbContext
    }
}
