using LifeLevel.Modules.Achievements.Application.DTOs;
using LifeLevel.Modules.Achievements.Domain.Entities;
using LifeLevel.Modules.Achievements.Domain.Enums;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using ActivityEntity = LifeLevel.Modules.Activity.Domain.Entities.Activity;
using StreakEntity = LifeLevel.Modules.Streak.Domain.Entities.Streak;

namespace LifeLevel.Modules.Achievements.Application.UseCases;

public class AchievementService(
    DbContext db,
    ICharacterXpPort xp,
    ICharacterIdReadPort charId)
{
    public async Task<List<AchievementDto>> GetAchievementsAsync(
        Guid userId, string? category, CancellationToken ct = default)
    {
        var query = db.Set<Achievement>().AsQueryable();

        if (!string.IsNullOrWhiteSpace(category) &&
            Enum.TryParse<AchievementCategory>(category, true, out var cat))
        {
            query = query.Where(a => a.Category == cat);
        }

        var achievements = await query.ToListAsync(ct);

        var userProgress = await db.Set<UserAchievement>()
            .Where(u => u.UserId == userId)
            .ToDictionaryAsync(u => u.AchievementId, ct);

        var dtos = achievements.Select(a =>
        {
            userProgress.TryGetValue(a.Id, out var ua);
            return new AchievementDto(
                a.Id,
                a.Title,
                a.Description,
                a.Icon,
                a.Category.ToString(),
                a.Tier.ToString(),
                a.XpReward,
                a.TargetValue,
                a.TargetUnit,
                ua?.CurrentValue ?? 0,
                ua?.IsUnlocked ?? false,
                ua?.UnlockedAt
            );
        }).ToList();

        return dtos
            .OrderByDescending(d => d.IsUnlocked ? 1 : 0)
            .ThenByDescending(d => d.UnlockedAt)
            .ThenByDescending(d => d.TargetValue > 0 ? d.CurrentValue / d.TargetValue : 0)
            .ThenBy(d => d.Title)
            .ToList();
    }

    public async Task<CheckUnlocksResult> CheckUnlocksAsync(
        Guid userId, CancellationToken ct = default)
    {
        var characterId = await charId.GetCharacterIdAsync(userId, ct);
        if (characterId is null)
            return new CheckUnlocksResult([]);

        var achievements = await db.Set<Achievement>().ToListAsync(ct);

        var progressDict = await db.Set<UserAchievement>()
            .Where(u => u.UserId == userId)
            .ToDictionaryAsync(u => u.AchievementId, ct);

        var newlyUnlocked = new List<Guid>();

        foreach (var achievement in achievements)
        {
            var currentValue = await ComputeConditionValueAsync(
                userId, characterId.Value, achievement.ConditionType, ct);

            if (progressDict.TryGetValue(achievement.Id, out var ua))
            {
                ua.CurrentValue = currentValue;
                if (!ua.IsUnlocked && currentValue >= achievement.TargetValue)
                {
                    ua.UnlockedAt = DateTime.UtcNow;
                    newlyUnlocked.Add(achievement.Id);
                    await xp.AwardXpAsync(userId, "Achievement", achievement.Icon,
                        achievement.Title, achievement.XpReward, ct);
                }
            }
            else
            {
                var newUa = new UserAchievement
                {
                    UserId = userId,
                    AchievementId = achievement.Id,
                    CurrentValue = currentValue
                };

                if (currentValue >= achievement.TargetValue)
                {
                    newUa.UnlockedAt = DateTime.UtcNow;
                    newlyUnlocked.Add(achievement.Id);
                    await xp.AwardXpAsync(userId, "Achievement", achievement.Icon,
                        achievement.Title, achievement.XpReward, ct);
                }

                db.Set<UserAchievement>().Add(newUa);
            }
        }

        await db.SaveChangesAsync(ct);
        return new CheckUnlocksResult(newlyUnlocked);
    }

    private async Task<double> ComputeConditionValueAsync(
        Guid userId, Guid characterId, ConditionType conditionType, CancellationToken ct)
    {
        return conditionType switch
        {
            ConditionType.TotalDistanceKm =>
                await db.Set<ActivityEntity>()
                    .Where(a => a.CharacterId == characterId)
                    .SumAsync(a => (double?)a.DistanceKm, ct) ?? 0,

            ConditionType.TotalRunningDistanceKm =>
                await db.Set<ActivityEntity>()
                    .Where(a => a.CharacterId == characterId &&
                                (a.Type == ActivityType.Running ||
                                 a.Type == ActivityType.Cycling ||
                                 a.Type == ActivityType.Hiking))
                    .SumAsync(a => (double?)a.DistanceKm, ct) ?? 0,

            ConditionType.TotalActivities =>
                await db.Set<ActivityEntity>()
                    .CountAsync(a => a.CharacterId == characterId, ct),

            ConditionType.TotalGymActivities =>
                await db.Set<ActivityEntity>()
                    .CountAsync(a => a.CharacterId == characterId &&
                                     a.Type == ActivityType.Gym, ct),

            ConditionType.MaxStreakDays =>
                await db.Set<StreakEntity>()
                    .Where(s => s.UserId == userId)
                    .Select(s => (double?)s.Longest)
                    .FirstOrDefaultAsync(ct) ?? 0,

            ConditionType.CurrentStreakDays =>
                await db.Set<StreakEntity>()
                    .Where(s => s.UserId == userId)
                    .Select(s => (double?)s.Current)
                    .FirstOrDefaultAsync(ct) ?? 0,

            ConditionType.BossesDefeated =>
                await db.Set<UserBossState>()
                    .CountAsync(b => b.UserId == userId && b.IsDefeated, ct),

            _ => 0
        };
    }
}
