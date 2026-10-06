using LifeLevel.Modules.Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Identity.Infrastructure.Persistence.Configurations;

public class UserExternalLoginConfiguration : IEntityTypeConfiguration<UserExternalLogin>
{
    public void Configure(EntityTypeBuilder<UserExternalLogin> entity)
    {
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Provider).HasMaxLength(40);
        entity.Property(x => x.ProviderSubject).HasMaxLength(255);
        entity.HasIndex(x => new { x.Provider, x.ProviderSubject }).IsUnique();
        entity.HasIndex(x => new { x.UserId, x.Provider }).IsUnique();
        entity.HasOne(x => x.User)
            .WithMany(x => x.ExternalLogins)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
