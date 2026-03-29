using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Dungeons.Infrastructure.Persistence.Configurations;

public class UserDungeonStateConfiguration : IEntityTypeConfiguration<UserDungeonState>
{
    public void Configure(EntityTypeBuilder<UserDungeonState> builder)
    {
        builder.HasKey(s => s.Id);
        builder.HasOne(s => s.DungeonPortal)
               .WithMany(d => d.UserStates)
               .HasForeignKey(s => s.DungeonPortalId);
        // UserId → User and UserMapProgressId → UserMapProgress are cross-module — configured in AppDbContext
    }
}
