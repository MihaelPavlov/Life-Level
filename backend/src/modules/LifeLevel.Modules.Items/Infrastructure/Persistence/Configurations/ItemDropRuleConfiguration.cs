using LifeLevel.Modules.Items.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LifeLevel.Modules.Items.Infrastructure.Persistence.Configurations;

public class ItemDropRuleConfiguration : IEntityTypeConfiguration<ItemDropRule>
{
    public void Configure(EntityTypeBuilder<ItemDropRule> builder)
    {
        builder.HasKey(r => r.Id);
        builder.Property(r => r.TriggerType).HasConversion<string>().HasMaxLength(50);
        builder.Property(r => r.TriggerParameters).HasMaxLength(2000);
        builder.HasOne(r => r.Item).WithMany().HasForeignKey(r => r.ItemId).OnDelete(DeleteBehavior.Cascade);
        builder.HasIndex(r => r.ItemId);
    }
}
