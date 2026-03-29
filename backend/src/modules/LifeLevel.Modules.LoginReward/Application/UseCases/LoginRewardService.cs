using LifeLevel.Modules.LoginReward.Application.DTOs;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using LoginRewardEntity = LifeLevel.Modules.LoginReward.Domain.Entities.LoginReward;

namespace LifeLevel.Modules.LoginReward.Application.UseCases;

public class LoginRewardService(
    DbContext db,
    ICharacterXpPort characterXp,
    IStreakShieldPort streakShield) : ILoginRewardReadPort, ILoginRewardDailyReset
{
    private static readonly (int Xp, bool IncludesShield, bool IsXpStorm)[] RewardTable =
    [
        (50,  false, false),
        (75,  false, false),
        (100, true,  false),
        (125, false, false),
        (150, false, false),
        (200, false, false),
        (300, false, true),
    ];

    public async Task<LoginRewardEntity> GetOrCreateAsync(Guid userId, CancellationToken ct = default)
    {
        var reward = await db.Set<LoginRewardEntity>().FirstOrDefaultAsync(r => r.UserId == userId, ct);
        if (reward != null) return reward;

        reward = new LoginRewardEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DayInCycle = 0,
            ClaimedToday = false,
            TotalLoginDays = 0,
        };
        db.Set<LoginRewardEntity>().Add(reward);
        await db.SaveChangesAsync(ct);
        return reward;
    }

    public async Task<LoginRewardStatusDto> GetStatusAsync(Guid userId)
    {
        var reward = await GetOrCreateAsync(userId);
        var nextDayIndex = reward.DayInCycle % 7;
        var (nextXp, nextShield, nextXpStorm) = RewardTable[nextDayIndex];

        return new LoginRewardStatusDto
        {
            DayInCycle = reward.DayInCycle,
            ClaimedToday = reward.ClaimedToday,
            NextRewardXp = nextXp,
            NextRewardIncludesShield = nextShield,
            NextRewardIsXpStorm = nextXpStorm,
            TotalLoginDays = reward.TotalLoginDays,
        };
    }

    public async Task<LoginRewardClaimResult> ClaimDailyRewardAsync(Guid userId)
    {
        var reward = await GetOrCreateAsync(userId);

        if (reward.ClaimedToday)
            throw new InvalidOperationException("Daily login reward already claimed today.");

        reward.DayInCycle = (reward.DayInCycle % 7) + 1;
        var dayIndex = reward.DayInCycle - 1;
        var (xp, includesShield, isXpStorm) = RewardTable[dayIndex];

        reward.ClaimedToday = true;
        reward.LastClaimedAt = DateTime.UtcNow;
        reward.TotalLoginDays++;

        await db.SaveChangesAsync();

        await characterXp.AwardXpAsync(userId, "DailyLogin", "📅", $"Day {reward.DayInCycle} login reward", xp);

        if (includesShield)
            await streakShield.AddShieldAsync(userId);

        if (isXpStorm)
            await characterXp.AwardXpAsync(userId, "XpStorm", "⚡", "Day 7 XP Storm bonus", 300);

        return new LoginRewardClaimResult
        {
            DayInCycle = reward.DayInCycle,
            XpAwarded = xp,
            IncludesShield = includesShield,
            IsXpStorm = isXpStorm,
            LeveledUp = false,
            NewLevel = null,
        };
    }

    // ILoginRewardReadPort
    public async Task<bool> HasClaimedTodayAsync(Guid userId, CancellationToken ct = default)
    {
        var reward = await db.Set<LoginRewardEntity>().FirstOrDefaultAsync(r => r.UserId == userId, ct);
        return reward?.ClaimedToday ?? false;
    }

    // ILoginRewardDailyReset
    public async Task ResetDailyClaimFlagsAsync(CancellationToken ct = default)
    {
        var all = await db.Set<LoginRewardEntity>().ToListAsync(ct);
        foreach (var r in all)
            r.ClaimedToday = false;
        await db.SaveChangesAsync(ct);
    }
}
