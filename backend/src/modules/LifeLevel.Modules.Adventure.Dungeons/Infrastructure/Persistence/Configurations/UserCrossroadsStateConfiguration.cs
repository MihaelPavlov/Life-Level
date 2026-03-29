using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Dungeons.Infrastructure.Persistence.Configurations;

public class UserCrossroadsStateConfiguration : IEntityTypeConfiguration<UserCrossroadsState>
{
    public void Configure(EntityTypeBuilder<UserCrossroadsState> builder)
    {
        builder.HasKey(s => s.Id);
        builder.HasOne(s => s.Crossroads)
               .WithMany(c => c.UserStates)
               .HasForeignKey(s => s.CrossroadsId);
        builder.HasOne(s => s.ChosenPath)
               .WithMany()
               .HasForeignKey(s => s.ChosenPathId)
               .IsRequired(false)
               .OnDelete(DeleteBehavior.Restrict);
        // UserId → User and UserMapProgressId → UserMapProgress are cross-module — configured in AppDbContext
    }
}
