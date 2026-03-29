using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure.Persistence.Configurations;

public class UserBossStateConfiguration : IEntityTypeConfiguration<UserBossState>
{
    public void Configure(EntityTypeBuilder<UserBossState> builder)
    {
        builder.HasKey(s => s.Id);
        builder.HasOne(s => s.Boss)
               .WithMany(b => b.UserStates)
               .HasForeignKey(s => s.BossId);
        // UserId → User and UserMapProgressId → UserMapProgress are cross-module — configured in AppDbContext
    }
}
