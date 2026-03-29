using LifeLevel.Modules.Quest.Application.DTOs;
using LifeLevel.Modules.Quest.Domain.Enums;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using QuestEntity = LifeLevel.Modules.Quest.Domain.Entities.Quest;
using UserQuestProgressEntity = LifeLevel.Modules.Quest.Domain.Entities.UserQuestProgress;

namespace LifeLevel.Modules.Quest.Application.UseCases;

public class QuestService(DbContext db, ICharacterXpPort characterXp, IEventPublisher events)
    : IDailyQuestReadPort
{
    // Far-future expiry used for special quests
    private static readonly DateTime SpecialQuestExpiry = new(2099, 12, 31, 23, 59, 59, DateTimeKind.Utc);

    public async Task<List<UserQuestProgressDto>> GetActiveQuestsAsync(Guid userId, QuestType type)
    {
        var now = DateTime.UtcNow;

        var query = db.Set<UserQuestProgressEntity>()
            .Include(p => p.Quest)
            .Where(p => p.UserId == userId && p.Quest.Type == type);

        // Special quests use a far-future expiry so we treat them as never expiring
        if (type == QuestType.Special)
            query = query.Where(p => p.ExpiresAt > now || p.ExpiresAt == SpecialQuestExpiry);
        else
            query = query.Where(p => p.ExpiresAt > now);

        var progresses = await query
            .OrderBy(p => p.IsCompleted)
            .ThenBy(p => p.Quest.SortOrder)
            .ToListAsync();

        return progresses.Select(MapToDto).ToList();
    }

    public async Task GenerateDailyQuestsAsync(Guid userId)
    {
        var now = DateTime.UtcNow;
        var existingCount = await db.Set<UserQuestProgressEntity>()
            .CountAsync(p => p.UserId == userId && p.Quest.Type == QuestType.Daily && p.ExpiresAt > now);

        if (existingCount >= 5) return;

        var templates = await db.Set<QuestEntity>()
            .Where(q => q.IsActive && q.Type == QuestType.Daily)
            .OrderBy(q => q.SortOrder)
            .ToListAsync();

        if (templates.Count == 0) return;

        // Already-assigned quest IDs for today
        var assignedIds = await db.Set<UserQuestProgressEntity>()
            .Where(p => p.UserId == userId && p.Quest.Type == QuestType.Daily && p.ExpiresAt > now)
            .Select(p => p.QuestId)
            .ToListAsync();

        var available = templates.Where(t => !assignedIds.Contains(t.Id)).ToList();
        if (available.Count == 0) return;

        var selected = SelectDailyQuests(available, 5 - existingCount);
        var expiresAt = now.Date.AddDays(1); // tomorrow midnight UTC

        foreach (var quest in selected)
        {
            db.Set<UserQuestProgressEntity>().Add(new UserQuestProgressEntity
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                QuestId = quest.Id,
                CurrentValue = 0,
                IsCompleted = false,
                RewardClaimed = false,
                AssignedAt = now,
                ExpiresAt = expiresAt,
                BonusAwarded = false,
            });
        }

        await db.SaveChangesAsync();
    }

    public async Task GenerateWeeklyQuestsAsync(Guid userId)
    {
        var now = DateTime.UtcNow;
        var hasWeekly = await db.Set<UserQuestProgressEntity>()
            .AnyAsync(p => p.UserId == userId && p.Quest.Type == QuestType.Weekly && p.ExpiresAt > now);

        if (hasWeekly) return;

        var templates = await db.Set<QuestEntity>()
            .Where(q => q.IsActive && q.Type == QuestType.Weekly)
            .OrderBy(q => q.SortOrder)
            .Take(3)
            .ToListAsync();

        // Next Sunday midnight UTC
        var daysUntilSunday = ((int)DayOfWeek.Sunday - (int)now.DayOfWeek + 7) % 7;
        if (daysUntilSunday == 0) daysUntilSunday = 7;
        var expiresAt = now.Date.AddDays(daysUntilSunday);

        foreach (var quest in templates)
        {
            db.Set<UserQuestProgressEntity>().Add(new UserQuestProgressEntity
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                QuestId = quest.Id,
                CurrentValue = 0,
                IsCompleted = false,
                RewardClaimed = false,
                AssignedAt = now,
                ExpiresAt = expiresAt,
                BonusAwarded = false,
            });
        }

        // Assign special quests that the user hasn't started yet
        await AssignSpecialQuestsAsync(userId, now);

        await db.SaveChangesAsync();
    }

    public async Task<QuestProgressUpdateResult> UpdateProgressFromActivityAsync(
        Guid userId,
        ActivityType activityType,
        int durationMinutes,
        double? distanceKm,
        int? calories)
    {
        var now = DateTime.UtcNow;

        var activeProgresses = await db.Set<UserQuestProgressEntity>()
            .Include(p => p.Quest)
            .Where(p => p.UserId == userId
                        && !p.IsCompleted
                        && (p.ExpiresAt > now || p.ExpiresAt == SpecialQuestExpiry))
            .ToListAsync();

        var updatedProgresses = new List<UserQuestProgressEntity>();

        foreach (var progress in activeProgresses)
        {
            var quest = progress.Quest;

            // Filter by required activity type
            if (quest.RequiredActivity.HasValue && quest.RequiredActivity.Value != activityType)
                continue;

            double delta = quest.Category switch
            {
                QuestCategory.Duration => durationMinutes,
                QuestCategory.Calories => calories ?? 0,
                QuestCategory.Distance => distanceKm ?? 0,
                QuestCategory.Workouts => 1,
                _ => 0,
            };

            if (delta == 0) continue;

            progress.CurrentValue += delta;

            var targetValue = quest.TargetValue ?? 0;
            if (progress.CurrentValue >= targetValue)
            {
                progress.IsCompleted = true;
                progress.CompletedAt = now;
                progress.RewardClaimed = true;

                await db.SaveChangesAsync();
                await characterXp.AwardXpAsync(userId, "Quest", "🎯", $"Quest complete: {quest.Title}", quest.RewardXp);

                updatedProgresses.Add(progress);
            }
        }

        await db.SaveChangesAsync();

        // Check all-5-daily bonus
        bool allDailyCompleted = false;
        int bonusXp = 0;

        var dailyCompleted = await db.Set<UserQuestProgressEntity>()
            .CountAsync(p => p.UserId == userId
                             && p.Quest.Type == QuestType.Daily
                             && p.IsCompleted
                             && p.ExpiresAt > now);

        var totalDailyAssigned = await db.Set<UserQuestProgressEntity>()
            .CountAsync(p => p.UserId == userId
                             && p.Quest.Type == QuestType.Daily
                             && p.ExpiresAt > now);

        if (dailyCompleted == 5 && totalDailyAssigned == 5)
        {
            var bonusAlreadyAwarded = await db.Set<UserQuestProgressEntity>()
                .AnyAsync(p => p.UserId == userId
                               && p.Quest.Type == QuestType.Daily
                               && p.ExpiresAt > now
                               && p.BonusAwarded);

            if (!bonusAlreadyAwarded)
            {
                await db.SaveChangesAsync();
                await characterXp.AwardXpAsync(userId, "DailyQuestBonus", "🎯", "All 5 daily quests completed!", 300);

                // Mark bonus on the first progress record for today
                var firstDailyProgress = await db.Set<UserQuestProgressEntity>()
                    .Include(p => p.Quest)
                    .FirstOrDefaultAsync(p => p.UserId == userId
                                              && p.Quest.Type == QuestType.Daily
                                              && p.IsCompleted
                                              && p.ExpiresAt > now);

                if (firstDailyProgress != null)
                {
                    firstDailyProgress.BonusAwarded = true;
                    await db.SaveChangesAsync();
                }

                allDailyCompleted = true;
                bonusXp = 300;
            }
        }

        return new QuestProgressUpdateResult
        {
            UpdatedQuests = updatedProgresses.Select(MapToDto).ToList(),
            AllDailyCompleted = allDailyCompleted,
            BonusXpAwarded = bonusXp,
        };
    }

    public Task ExpireStaleQuestsAsync()
    {
        // Quests auto-expire via ExpiresAt checks in queries — nothing to delete
        return Task.CompletedTask;
    }

    // IDailyQuestReadPort
    public async Task<int> CountCompletedDailyQuestsAsync(Guid userId, CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        return await db.Set<UserQuestProgressEntity>()
            .CountAsync(p => p.UserId == userId
                             && p.Quest.Type == QuestType.Daily
                             && p.IsCompleted
                             && p.ExpiresAt > now, ct);
    }

    // ── Private helpers ────────────────────────────────────────────────────────

    private async Task AssignSpecialQuestsAsync(Guid userId, DateTime now)
    {
        var specialTemplates = await db.Set<QuestEntity>()
            .Where(q => q.IsActive && q.Type == QuestType.Special)
            .ToListAsync();

        var alreadyAssignedSpecialIds = await db.Set<UserQuestProgressEntity>()
            .Where(p => p.UserId == userId && p.Quest.Type == QuestType.Special)
            .Select(p => p.QuestId)
            .ToListAsync();

        foreach (var quest in specialTemplates)
        {
            if (alreadyAssignedSpecialIds.Contains(quest.Id)) continue;

            db.Set<UserQuestProgressEntity>().Add(new UserQuestProgressEntity
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                QuestId = quest.Id,
                CurrentValue = 0,
                IsCompleted = false,
                RewardClaimed = false,
                AssignedAt = now,
                ExpiresAt = SpecialQuestExpiry,
                BonusAwarded = false,
            });
        }
    }

    private static List<QuestEntity> SelectDailyQuests(List<QuestEntity> available, int count)
    {
        if (available.Count <= count)
            return available;

        var selected = new List<QuestEntity>();

        // Pick 1 Duration quest
        var durationQuest = available
            .FirstOrDefault(q => q.Category == QuestCategory.Duration);
        if (durationQuest != null)
        {
            selected.Add(durationQuest);
            available = available.Where(q => q.Id != durationQuest.Id).ToList();
        }

        if (selected.Count < count)
        {
            // Pick 1 Calories or Distance quest
            var caloriesOrDistance = available
                .FirstOrDefault(q => q.Category == QuestCategory.Calories || q.Category == QuestCategory.Distance);
            if (caloriesOrDistance != null)
            {
                selected.Add(caloriesOrDistance);
                available = available.Where(q => q.Id != caloriesOrDistance.Id).ToList();
            }
        }

        // Fill remaining slots from the rest of the pool
        var rng = new Random();
        var remaining = available.OrderBy(_ => rng.Next()).Take(count - selected.Count);
        selected.AddRange(remaining);

        return selected;
    }

    private static UserQuestProgressDto MapToDto(UserQuestProgressEntity p) => new()
    {
        Id = p.Id,
        QuestId = p.QuestId,
        Title = p.Quest.Title,
        Description = p.Quest.Description,
        Category = p.Quest.Category.ToString(),
        RequiredActivity = p.Quest.RequiredActivity?.ToString(),
        TargetValue = p.Quest.TargetValue ?? 0,
        CurrentValue = p.CurrentValue,
        TargetUnit = p.Quest.TargetUnit,
        RewardXp = p.Quest.RewardXp,
        IsCompleted = p.IsCompleted,
        RewardClaimed = p.RewardClaimed,
        ExpiresAt = p.ExpiresAt,
        CompletedAt = p.CompletedAt,
    };
}
