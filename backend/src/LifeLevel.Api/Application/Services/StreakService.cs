using LifeLevel.Api.Application.DTOs.Streak;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class StreakService(AppDbContext db)
{
    public async Task<Streak> GetOrCreateAsync(Guid userId)
    {
        var streak = await db.Streaks.FirstOrDefaultAsync(s => s.UserId == userId);
        if (streak != null) return streak;

        streak = new Streak
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
        db.Streaks.Add(streak);
        await db.SaveChangesAsync();
        return streak;
    }

    public async Task<StreakDto> GetDtoAsync(Guid userId)
    {
        var streak = await GetOrCreateAsync(userId);
        return MapToDto(streak);
    }

    public async Task<StreakUpdateResult> RecordActivityDayAsync(Guid userId, DateTime activityUtcDate)
    {
        var today = activityUtcDate.Date;
        var streak = await GetOrCreateAsync(userId);

        // Already counted today — no update needed
        if (streak.LastActivityDate.HasValue && streak.LastActivityDate.Value.Date == today)
        {
            return new StreakUpdateResult
            {
                Updated = false,
                Current = streak.Current
            };
        }

        bool shieldUsed = false;
        bool broke = false;
        bool shieldAwarded = false;

        if (streak.LastActivityDate == null)
        {
            // First activity ever
            streak.Current = 1;
        }
        else if (streak.LastActivityDate.Value.Date == today.AddDays(-1))
        {
            // Consecutive day
            streak.Current += 1;
        }
        else if (streak.LastActivityDate.Value.Date == today.AddDays(-2)
                 && streak.ShieldsAvailable > 0
                 && !streak.ShieldUsedToday)
        {
            // Shield bridges a one-day gap
            streak.ShieldsAvailable--;
            streak.ShieldsUsed++;
            streak.ShieldUsedToday = true;
            streak.Current += 1;
            shieldUsed = true;
        }
        else
        {
            // Streak broken
            broke = streak.TotalDaysActive > 0;
            streak.Current = 1;
        }

        streak.LastActivityDate = today;
        streak.TotalDaysActive++;

        if (streak.Current > streak.Longest)
            streak.Longest = streak.Current;

        // Award a shield every 7 total active days
        if (streak.TotalDaysActive % 7 == 0)
        {
            streak.ShieldsAvailable++;
            shieldAwarded = true;
        }

        await db.SaveChangesAsync();

        return new StreakUpdateResult
        {
            Updated = true,
            ShieldUsed = shieldUsed,
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

    public async Task CheckAndBreakExpiredStreaksAsync()
    {
        var today = DateTime.UtcNow.Date;
        var streaks = await db.Streaks.ToListAsync();

        foreach (var streak in streaks)
        {
            // Reset daily shield flag
            streak.ShieldUsedToday = false;

            if (!streak.LastActivityDate.HasValue || streak.Current == 0)
                continue;

            var lastDate = streak.LastActivityDate.Value.Date;

            // Gap is 2 days but no shield available — streak expires
            var gapDays = (today - lastDate).TotalDays;
            if (gapDays >= 2 && streak.ShieldsAvailable == 0)
            {
                streak.Current = 0;
            }
            // Gap is 3+ days regardless of shields
            else if (gapDays >= 3)
            {
                streak.Current = 0;
            }
        }

        await db.SaveChangesAsync();
    }

    public async Task AddShieldAsync(Guid userId)
    {
        var streak = await GetOrCreateAsync(userId);
        streak.ShieldsAvailable++;
        await db.SaveChangesAsync();
    }

    private static StreakDto MapToDto(Streak streak) => new()
    {
        Current = streak.Current,
        Longest = streak.Longest,
        ShieldsAvailable = streak.ShieldsAvailable,
        ShieldUsedToday = streak.ShieldUsedToday,
        LastActivityDate = streak.LastActivityDate,
        TotalDaysActive = streak.TotalDaysActive,
    };
}

public class StreakUpdateResult
{
    public bool Updated { get; set; }
    public bool ShieldUsed { get; set; }
    public bool StreakBroke { get; set; }
    public int Current { get; set; }
    public bool ShieldAwarded { get; set; }
}
