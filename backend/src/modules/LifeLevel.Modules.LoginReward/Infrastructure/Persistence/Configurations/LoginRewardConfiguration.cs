using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using LoginRewardEntity = LifeLevel.Modules.LoginReward.Domain.Entities.LoginReward;

namespace LifeLevel.Modules.LoginReward.Infrastructure.Persistence.Configurations;

public class LoginRewardConfiguration : IEntityTypeConfiguration<LoginRewardEntity>
{
    public void Configure(EntityTypeBuilder<LoginRewardEntity> entity)
    {
        entity.HasKey(x => x.Id);
        // Cross-module: LoginReward → User FK configured in AppDbContext
    }
}
