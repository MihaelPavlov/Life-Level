using LifeLevel.Modules.Streak.Application.DTOs;
using LifeLevel.Modules.Streak.Domain.Events;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using StreakEntity = LifeLevel.Modules.Streak.Domain.Entities.Streak;

namespace LifeLevel.Modules.Streak.Application.UseCases;

public class StreakService(DbContext db, IEventPublisher events)
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

        await db.SaveChangesAsync(ct);

        if (broke)
            await events.PublishAsync(new StreakBrokenEvent(userId, previousStreak), ct);

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
    };
}
