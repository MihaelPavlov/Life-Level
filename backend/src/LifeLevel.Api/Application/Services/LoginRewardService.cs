using LifeLevel.Api.Application.DTOs.LoginReward;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class LoginRewardService(AppDbContext db, CharacterService characterService, StreakService streakService)
{
    // Index 0 = Day 1, index 6 = Day 7
    private static readonly (int Xp, bool IncludesShield, bool IsXpStorm)[] RewardTable =
    [
        (50,  false, false),  // Day 1
        (75,  false, false),  // Day 2
        (100, true,  false),  // Day 3 — shield
        (125, false, false),  // Day 4
        (150, false, false),  // Day 5
        (200, false, false),  // Day 6
        (300, false, true),   // Day 7 — XP storm bonus
    ];

    public async Task<LoginReward> GetOrCreateAsync(Guid userId)
    {
        var reward = await db.LoginRewards.FirstOrDefaultAsync(r => r.UserId == userId);
        if (reward != null) return reward;

        reward = new LoginReward
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DayInCycle = 0,
            ClaimedToday = false,
            TotalLoginDays = 0,
        };
        db.LoginRewards.Add(reward);
        await db.SaveChangesAsync();
        return reward;
    }

    public async Task<LoginRewardStatusDto> GetStatusAsync(Guid userId)
    {
        var reward = await GetOrCreateAsync(userId);

        // The next reward is for the day we haven't claimed yet (index into RewardTable)
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

        // Advance the day cycle (1–7, wraps back to 1 after 7)
        reward.DayInCycle = (reward.DayInCycle % 7) + 1;
        var dayIndex = reward.DayInCycle - 1;
        var (xp, includesShield, isXpStorm) = RewardTable[dayIndex];

        // Get character for XP award
        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        // Apply login reward XP
        character.Xp += xp;
        character.UpdatedAt = DateTime.UtcNow;

        reward.ClaimedToday = true;
        reward.LastClaimedAt = DateTime.UtcNow;
        reward.TotalLoginDays++;

        await db.SaveChangesAsync();

        // Log XP history (RecordXpAsync also calls CheckAndApplyLevelUpsAsync internally)
        await characterService.RecordXpAsync(character, "DailyLogin", "📅", $"Day {reward.DayInCycle} login reward", xp);

        // Award streak shield on Day 3
        if (includesShield)
            await streakService.AddShieldAsync(userId);

        // Day 7 XP storm: award an additional 300 XP
        bool leveledUp = false;
        int newLevel = 0;
        if (isXpStorm)
        {
            // Reload character to get latest state after first RecordXpAsync
            character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId)!
                ?? throw new InvalidOperationException("Character not found.");
            character.Xp += 300;
            character.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
            (leveledUp, newLevel) = await characterService.RecordXpAsync(character, "XpStorm", "⚡", "Day 7 XP Storm bonus", 300);
        }
        else
        {
            // Level-up state comes from the RecordXpAsync call above — we need to re-check
            (leveledUp, newLevel) = await characterService.CheckAndApplyLevelUpsAsync(character.Id);
        }

        return new LoginRewardClaimResult
        {
            DayInCycle = reward.DayInCycle,
            XpAwarded = xp,
            IncludesShield = includesShield,
            IsXpStorm = isXpStorm,
            LeveledUp = leveledUp,
            NewLevel = leveledUp ? newLevel : null,
        };
    }

    public async Task ResetDailyClaimFlagsAsync()
    {
        var all = await db.LoginRewards.ToListAsync();
        foreach (var r in all)
            r.ClaimedToday = false;

        await db.SaveChangesAsync();
    }
}
