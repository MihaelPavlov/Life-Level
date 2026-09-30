using LifeLevel.Modules.Modes.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Modes.Infrastructure.Persistence.Configurations;

public class BurnChainRunConfiguration : IEntityTypeConfiguration<BurnChainRun>
{
    public void Configure(EntityTypeBuilder<BurnChainRun> e)
    {
        e.HasKey(x => x.Id);
        e.HasIndex(x => new { x.UserId, x.StartedAtUtc });
        e.Property(x => x.EndReason).HasMaxLength(20);
        e.Property(x => x.LinksJson).HasColumnType("jsonb");
    }
}

public class TreasureDelveRunConfiguration : IEntityTypeConfiguration<TreasureDelveRun>
{
    public void Configure(EntityTypeBuilder<TreasureDelveRun> e)
    {
        e.HasKey(x => x.Id);
        e.HasIndex(x => new { x.UserId, x.EntryDateUtc });
        e.Property(x => x.Phase).HasMaxLength(20);
        e.Property(x => x.EndReason).HasMaxLength(20);
        e.Property(x => x.FeaturedStat).HasMaxLength(10);
        e.Property(x => x.ChosenPath).HasMaxLength(20);
        e.Property(x => x.OptionsJson).HasColumnType("jsonb");
        e.Property(x => x.HistoryJson).HasColumnType("jsonb");
        e.Property(x => x.ItemsJson).HasColumnType("jsonb");
    }
}

public class ModeRewardSettlementConfiguration : IEntityTypeConfiguration<ModeRewardSettlement>
{
    public void Configure(EntityTypeBuilder<ModeRewardSettlement> e)
    {
        e.HasKey(x => x.Id);
        e.HasIndex(x => new { x.Mode, x.RunId }).IsUnique();
        e.Property(x => x.Mode).HasMaxLength(30);
    }
}
