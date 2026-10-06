using LifeLevel.Modules.Waitlist.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Waitlist.Infrastructure.Persistence.Configurations;

public class WaitlistSignupConfiguration : IEntityTypeConfiguration<WaitlistSignup>
{
    public void Configure(EntityTypeBuilder<WaitlistSignup> entity)
    {
        entity.ToTable("WaitlistSignups");
        entity.HasKey(x => x.Id);
        entity.Property(x => x.Email).HasMaxLength(254).IsRequired();
        entity.HasIndex(x => x.Email).IsUnique();
        entity.HasIndex(x => x.CreatedAt);
        entity.HasIndex(x => new { x.IpHash, x.CreatedAt });
        entity.Property(x => x.Source).HasMaxLength(40);
        entity.Property(x => x.UtmSource).HasMaxLength(100);
        entity.Property(x => x.UtmMedium).HasMaxLength(100);
        entity.Property(x => x.UtmCampaign).HasMaxLength(100);
        entity.Property(x => x.Referrer).HasMaxLength(500);
        entity.Property(x => x.Locale).HasMaxLength(20);
        entity.Property(x => x.UserAgent).HasMaxLength(300);
        entity.Property(x => x.IpHash).HasMaxLength(64);
    }
}
