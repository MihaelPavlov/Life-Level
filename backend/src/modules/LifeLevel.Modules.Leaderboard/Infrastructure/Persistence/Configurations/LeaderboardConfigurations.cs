using LifeLevel.Modules.Leaderboard.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Leaderboard.Infrastructure.Persistence.Configurations;

public class LeaderboardPassConfiguration : IEntityTypeConfiguration<LeaderboardPass>
{
    public void Configure(EntityTypeBuilder<LeaderboardPass> b)
    {
        b.HasKey(x => x.Id);
        b.Property(x => x.PassedUsername).HasMaxLength(64);
        b.Property(x => x.PassedAvatarEmoji).HasMaxLength(64);
        // A pass pays once per player per week.
        b.HasIndex(x => new { x.UserId, x.PassedUserId, x.WeekStartUtc }).IsUnique();
        b.HasIndex(x => new { x.UserId, x.ClaimedAtUtc });
    }
}

public class LeaderboardWatchConfiguration : IEntityTypeConfiguration<LeaderboardWatch>
{
    public void Configure(EntityTypeBuilder<LeaderboardWatch> b)
    {
        b.HasKey(x => x.Id);
        b.HasIndex(x => x.UserId).IsUnique();
    }
}
