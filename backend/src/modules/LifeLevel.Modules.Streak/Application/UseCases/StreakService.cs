using LifeLevel.Modules.Streak.Application.DTOs;
using LifeLevel.Modules.Streak.Domain.Events;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using StreakEntity = LifeLevel.Modules.Streak.Domain.Entities.Streak;

namespace LifeLevel.Modules.Streak.Application.UseCases;

public class StreakService(
    DbContext db,
    IEventPublisher events,
    IRewardCurrencyPort rewardCurrency,
    ITalentStreakAssistPort? talentAssist = null)
    : IStreakReadPort, IStreakShieldPort, IStreakDailyReset
{
    public async Task<StreakEntity> GetOrCreateAsync(Guid userId, CancellationToken ct = default)
    {
        var streak = await db.Set<StreakEntity>().FirstOrDefaultAsync(s => s.UserId == userId, ct);
        if (streak != null) return streak;

        streak = new StreakEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Current = 0,
            Longest = 0,
            ShieldsAvailable = 0,
            ShieldsUsed = 0,
            ShieldUsedToday = false,
            TotalDaysActive = 0,
        };
        db.Set<StreakEntity>().Add(streak);
        await db.SaveChangesAsync(ct);
        return streak;
    }

    public async Task<StreakDto> GetDtoAsync(Guid userId)
    {
        var streak = await GetOrCreateAsync(userId);
        return MapToDto(streak);
    }

    public async Task<StreakUpdateResult> RecordActivityDayAsync(Guid userId, DateTime activityUtcDate, CancellationToken ct = default)
    {
        var today = activityUtcDate.Date;
        var streak = await GetOrCreateAsync(userId, ct);

        if (streak.LastActivityDate.HasValue && streak.LastActivityDate.Value.Date == today)
        {
            return new StreakUpdateResult { Updated = false, Current = streak.Current };
        }

        bool shieldUsed = false;
        bool secondWindUsed = false;
        bool broke = false;
        bool shieldAwarded = false;
        int previousStreak = streak.Current;

        if (streak.LastActivityDate == null)
        {
            streak.Current = 1;
        }
        else if (streak.LastActivityDate.Value.Date == today.AddDays(-1))
        {
            streak.Current += 1;
        }
        else if (streak.LastActivityDate.Value.Date == today.AddDays(-2)
                 && streak.ShieldsAvailable > 0
                 && !streak.ShieldUsedToday)
        {
            streak.ShieldsAvailable--;
            streak.ShieldsUsed++;
            streak.ShieldUsedToday = true;
            streak.Current += 1;
            shieldUsed = true;
        }
        else if (streak.LastActivityDate.Value.Date == today.AddDays(-2)
                 && !streak.ShieldUsedToday
                 && talentAssist is not null
                 && await talentAssist.TryConsumeSecondWindAsync(userId, today, ct))
        {
            // "Second Wind" talent — a free auto-save when no shield is available.
            streak.ShieldUsedToday = true;
            streak.Current += 1;
            secondWindUsed = true;
        }
        else
        {
            broke = streak.TotalDaysActive > 0;
            streak.Current = 1;
        }

        streak.LastActivityDate = today;
        streak.TotalDaysActive++;

        if (streak.Current > streak.Longest)
            streak.Longest = streak.Current;

        if (streak.TotalDaysActive % 7 == 0)
        {
            streak.ShieldsAvailable++;
            shieldAwarded = true;
        }

        // Every newly completed streak day creates a manually claimable coin
        // reward. The amount grows with the active streak and resets naturally
        // to 10 when a broken streak starts again at day 1.
        if (streak.LastRewardedStreakDate?.Date != today)
        {
            streak.PendingRewardCoins += streak.Current * 10;
            streak.LastRewardedStreakDate = today;
        }

        await db.SaveChangesAsync(ct);

        if (broke)
            await events.PublishAsync(new StreakBrokenEvent(userId, previousStreak), ct);

        return new StreakUpdateResult
        {
            Updated = true,
            ShieldUsed = shieldUsed || secondWindUsed,
            StreakBroke = broke,
            Current = streak.Current,
            ShieldAwarded = shieldAwarded
        };
    }

    public async Task<UseShieldResult> UseShieldAsync(Guid userId)
    {
        var streak = await GetOrCreateAsync(userId);

        if (streak.ShieldsAvailable <= 0)
            return new UseShieldResult { Success = false, Message = "No shields available.", ShieldsRemaining = 0 };

        if (streak.ShieldUsedToday)
            return new UseShieldResult { Success = false, Message = "Shield already used today.", ShieldsRemaining = streak.ShieldsAvailable };

        streak.ShieldsAvailable--;
        streak.ShieldsUsed++;
        streak.ShieldUsedToday = true;

        if (streak.Current == 0)
            streak.Current = 1;

        await db.SaveChangesAsync();

        return new UseShieldResult
        {
            Success = true,
            Message = "Shield activated. Your streak is protected for today.",
            ShieldsRemaining = streak.ShieldsAvailable
        };
    }

    public async Task<ClaimStreakRewardResult> ClaimDailyRewardAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var streak = await GetOrCreateAsync(userId, ct);
        if (streak.PendingRewardCoins <= 0)
        {
            return new ClaimStreakRewardResult
            {
                Success = false,
                Message = "No streak reward is ready to claim."
            };
        }

        var coins = streak.PendingRewardCoins;
        streak.PendingRewardCoins = 0;
        await rewardCurrency.AddCoinsAsync(userId, coins, ct);

        return new ClaimStreakRewardResult
        {
            Success = true,
            Message = $"Streak reward claimed: {coins} coins.",
            CoinsClaimed = coins
        };
    }

    // IStreakReadPort
    public async Task<StreakReadDto?> GetCurrentStreakAsync(Guid userId, CancellationToken ct = default)
    {
        var streak = await db.Set<StreakEntity>().FirstOrDefaultAsync(s => s.UserId == userId, ct);
        if (streak == null) return null;
        return new StreakReadDto(streak.Current, streak.Longest, streak.ShieldsAvailable);
    }

    // IStreakShieldPort
    public async Task AddShieldAsync(Guid userId, CancellationToken ct = default)
    {
        var streak = await GetOrCreateAsync(userId, ct);
        streak.ShieldsAvailable++;
        await db.SaveChangesAsync(ct);
    }

    // IStreakDailyReset
    public async Task CheckAndBreakExpiredStreaksAsync(CancellationToken ct = default)
    {
        var today = DateTime.UtcNow.Date;
        var streaks = await db.Set<StreakEntity>().ToListAsync(ct);

        foreach (var streak in streaks)
        {
            if (!streak.LastActivityDate.HasValue || streak.Current == 0)
                continue;

            var lastDate = streak.LastActivityDate.Value.Date;
            var gapDays = (today - lastDate).TotalDays;
            if (gapDays >= 2 && streak.ShieldsAvailable == 0)
            {
                streak.Current = 0;
            }
            else if (gapDays >= 3)
            {
                streak.Current = 0;
            }
        }

        await db.SaveChangesAsync(ct);
    }

    // IStreakDailyReset
    public async Task ResetShieldUsedTodayFlagsAsync(CancellationToken ct = default)
    {
        var streaks = await db.Set<StreakEntity>().ToListAsync(ct);
        foreach (var streak in streaks)
            streak.ShieldUsedToday = false;
        await db.SaveChangesAsync(ct);
    }

    private static StreakDto MapToDto(StreakEntity streak) => new()
    {
        Current = streak.Current,
        Longest = streak.Longest,
        ShieldsAvailable = streak.ShieldsAvailable,
        ShieldUsedToday = streak.ShieldUsedToday,
        LastActivityDate = streak.LastActivityDate,
        TotalDaysActive = streak.TotalDaysActive,
        PendingRewardCoins = streak.PendingRewardCoins,
        CanClaimDailyReward = streak.PendingRewardCoins > 0,
        NextRewardCoins = (streak.Current + 1) * 10,
    };
}
