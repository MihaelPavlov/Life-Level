using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Adventure.Encounters.Infrastructure.Persistence.Configurations;

public class UserChestStateConfiguration : IEntityTypeConfiguration<UserChestState>
{
    public void Configure(EntityTypeBuilder<UserChestState> builder)
    {
        builder.HasKey(s => s.Id);
        builder.HasOne(s => s.Chest)
               .WithMany(c => c.UserStates)
               .HasForeignKey(s => s.ChestId);
        // UserId → User and UserMapProgressId → UserMapProgress are cross-module — configured in AppDbContext
    }
}
