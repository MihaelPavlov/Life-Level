using LifeLevel.Modules.Activity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Activity.Infrastructure.Persistence.Configurations;

public sealed class TrackedSessionConfiguration : IEntityTypeConfiguration<TrackedSession>
{
    public void Configure(EntityTypeBuilder<TrackedSession> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Type).HasConversion<string>();
        entity.HasIndex(x => new { x.UserId, x.EndedAtUtc });
    }
}
