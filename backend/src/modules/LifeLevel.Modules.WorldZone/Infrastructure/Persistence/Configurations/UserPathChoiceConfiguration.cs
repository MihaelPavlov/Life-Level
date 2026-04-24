using LifeLevel.Modules.WorldZone.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.WorldZone.Infrastructure.Persistence.Configurations;

public class UserPathChoiceConfiguration : IEntityTypeConfiguration<UserPathChoice>
{
    public void Configure(EntityTypeBuilder<UserPathChoice> builder)
    {
        builder.HasKey(c => c.Id);

        builder.Property(c => c.UserId).IsRequired();
        builder.Property(c => c.CrossroadsZoneId).IsRequired();
        builder.Property(c => c.ChosenBranchZoneId).IsRequired();
        builder.Property(c => c.ChosenAt).IsRequired();

        // One choice per user per crossroads. Enforced at DB level.
        builder.HasIndex(c => new { c.UserId, c.CrossroadsZoneId }).IsUnique();
    }
}
