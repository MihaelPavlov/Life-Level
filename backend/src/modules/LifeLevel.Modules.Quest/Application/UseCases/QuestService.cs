using LifeLevel.Modules.Quest.Application.DTOs;
using LifeLevel.Modules.Quest.Domain.Entities;
using LifeLevel.Modules.Quest.Domain.Enums;
using LifeLevel.Modules.Quest.Domain.Events;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using QuestEntity = LifeLevel.Modules.Quest.Domain.Entities.Quest;
using UserQuestProgressEntity = LifeLevel.Modules.Quest.Domain.Entities.UserQuestProgress;

namespace LifeLevel.Modules.Quest.Application.UseCases;

public class QuestService(
    DbContext db,
    ICharacterXpPort characterXp,
    IEventPublisher events,
    ILevelUpItemGrantPort levelUpItemGrant,
    ITalentBonusReadPort? talentBonus = null,
    IRewardCurrencyPort? rewardCurrency = null,
    IStreakShieldPort? streakShield = null,
    IActivityHistoryReadPort? activityHistory = null,
    ITaskEligibilityReadPort? taskEligibility = null)
    : IDailyQuestReadPort, IQuestProgressPort
{
    private const int DailyTasks = 5;
    private const int WeeklyTasks = 10;
    private static readonly DateTime SpecialQuestExpiry = new(2099, 12, 31, 23, 59, 59, DateTimeKind.Utc);

    private static readonly IReadOnlyDictionary<int, TaskMilestoneRewardDto> DailyMilestones =
        new Dictionary<int, TaskMilestoneRewardDto>
        {
            [20] = new(25, 0, 0, 0), [40] = new(0, 0, 50, 0),
            [60] = new(0, 1, 0, 0), [80] = new(75, 0, 0, 0),
            [100] = new(0, 0, 150, 1),
        };

    private static readonly IReadOnlyDictionary<int, TaskMilestoneRewardDto> WeeklyMilestones =
        new Dictionary<int, TaskMilestoneRewardDto>
        {
            [40] = new(100, 0, 0, 0), [80] = new(0, 0, 150, 0),
            [120] = new(0, 2, 0, 0), [160] = new(200, 0, 0, 0),
            [200] = new(0, 0, 500, 1),
        };

    public async Task<List<UserQuestProgressDto>> GetActiveQuestsAsync(Guid userId, QuestType type)
    {
        var now = DateTime.UtcNow;
        var query = db.Set<UserQuestProgressEntity>().Include(p => p.Quest)
            .Where(p => p.UserId == userId && p.Quest.Type == type);
        query = type == QuestType.Special
            ? query.Where(p => p.ExpiresAt > now || p.ExpiresAt == SpecialQuestExpiry)
            : query.Where(p => p.ExpiresAt > now);
        return (await query.OrderBy(p => p.IsCompleted).ThenBy(p => p.Quest.SortOrder).ToListAsync())
            .Select(MapToDto).ToList();
    }

    public Task GenerateDailyQuestsAsync(Guid userId) => GeneratePeriodTasksAsync(userId, QuestType.Daily);
    public Task GenerateWeeklyQuestsAsync(Guid userId) => GeneratePeriodTasksAsync(userId, QuestType.Weekly);

    private async Task GeneratePeriodTasksAsync(Guid userId, QuestType type)
    {
        var now = DateTime.UtcNow;
        var active = await db.Set<UserQuestProgressEntity>().Include(p => p.Quest)
            .Where(p => p.UserId == userId && p.Quest.Type == type && p.ExpiresAt > now).ToListAsync();
        var desiredCount = type == QuestType.Daily ? DailyTasks : WeeklyTasks;
        if (active.Count < desiredCount)
        {
            var assignedIds = active.Select(p => p.QuestId).ToHashSet();
            var available = await db.Set<QuestEntity>()
                .Where(q => q.IsActive && q.Type == type && !assignedIds.Contains(q.Id)).ToListAsync();
            var selected = await SelectBalancedTasksAsync(
                userId, type, available, desiredCount - active.Count);
            var (_, resetAt) = PeriodBounds(type, now);
            foreach (var task in selected)
            {
                var progress = new UserQuestProgressEntity
                {
                    UserId = userId, QuestId = task.Id, Quest = task,
                    AssignedAt = now, ExpiresAt = resetAt,
                };
                active.Add(progress);
                db.Set<UserQuestProgressEntity>().Add(progress);
            }
        }
        var (_, canonicalResetAt) = PeriodBounds(type, now);
        foreach (var progress in active) progress.ExpiresAt = canonicalResetAt;
        ApplyRewardSnapshots(active, type, desiredCount);
        await db.SaveChangesAsync();
    }

    private async Task<List<QuestEntity>> SelectBalancedTasksAsync(
        Guid userId, QuestType type, List<QuestEntity> available, int count)
    {
        if (count <= 0) return [];

        var eligibility = taskEligibility is null
            ? new TaskEligibilitySnapshot(false, 0, false, false, false)
            : await taskEligibility.GetAsync(userId);
        available = available.Where(q => IsEligible(q, eligibility)).ToList();

        IReadOnlyList<ActivityRecordDto> history = [];
        if (activityHistory != null)
            history = await activityHistory.ListForUserBetweenAsync(
                userId, DateTime.UtcNow.AddDays(-28), DateTime.UtcNow);

        var variants = available
            .GroupBy(GroupKeyOf)
            .Select(group => SelectPersonalVariant(group.ToList(), type, history))
            .Where(q => q != null)
            .Cast<QuestEntity>()
            .ToList();

        var gameCap = type == QuestType.Daily ? 1 : 2;
        var game = variants.Where(IsGameTask).OrderBy(_ => Random.Shared.Next()).Take(gameCap).ToList();
        var fitness = variants.Where(q => !IsGameTask(q)).OrderBy(_ => Random.Shared.Next()).ToList();
        var selected = fitness.Take(Math.Max(0, count - game.Count)).Concat(game).ToList();
        if (selected.Count < count)
        {
            // Keep the selected count stable even for a brand-new player with
            // little activity history. Fill only with the easiest unused
            // fitness groups; unavailable adventure/guild tasks remain out.
            var usedGroups = selected.Select(GroupKeyOf).ToHashSet();
            var fallback = available.Where(q => !IsGameTask(q) && !usedGroups.Contains(GroupKeyOf(q)))
                .GroupBy(GroupKeyOf)
                .Select(g => g.OrderBy(q => q.TargetValue ?? 0).First())
                .OrderBy(_ => Random.Shared.Next());
            selected.AddRange(fallback
                .Take(count - selected.Count));
        }
        return selected.OrderBy(q => q.SortOrder).ToList();
    }

    private static void ApplyRewardSnapshots(List<UserQuestProgressEntity> tasks, QuestType type, int desiredCount)
    {
        // Reward snapshots are immutable once assigned. This preserves active
        // v1 periods during rollout and prevents a later catalog reorder from
        // changing rewards already shown to the player.
        if (tasks.Any(p => p.RewardPoints > 0)) return;
        var ordered = tasks.OrderBy(p => p.Quest.SortOrder).ThenBy(p => p.Id).Take(desiredCount).ToList();
        var crystalCount = type == QuestType.Daily ? 1 : 2;
        var points = 20;
        var coins = type == QuestType.Daily ? 35 : 30;
        for (var i = 0; i < ordered.Count; i++)
        {
            ordered[i].RewardPoints = points;
            var crystalReward = i >= ordered.Count - crystalCount;
            ordered[i].RewardCoins = crystalReward ? 0 : coins;
            ordered[i].RewardCrystals = crystalReward ? 1 : 0;
        }
    }

    private static bool IsGameTask(QuestEntity quest) => quest.Category is
        QuestCategory.ZonesCompleted or QuestCategory.ChestsOpened or
        QuestCategory.BossContributions or QuestCategory.BossesDefeated or
        QuestCategory.GuildRaidContributions or QuestCategory.GuildRaidsWon or
        QuestCategory.RegionsCompleted;

    private static bool IsEligible(QuestEntity quest, TaskEligibilitySnapshot eligibility) => quest.Category switch
    {
        QuestCategory.ZonesCompleted => eligibility.HasCompletableZone,
        QuestCategory.ChestsOpened => eligibility.ReachableUnopenedChests >= quest.TargetValue,
        QuestCategory.BossContributions or QuestCategory.BossesDefeated => eligibility.HasActiveBoss,
        QuestCategory.GuildRaidContributions or QuestCategory.GuildRaidsWon => eligibility.HasActiveGuildRaid,
        QuestCategory.RegionsCompleted => quest.Type == QuestType.Weekly && eligibility.CanCompleteCurrentRegion,
        _ => true,
    };

    private static string GroupKeyOf(QuestEntity quest) => string.IsNullOrWhiteSpace(quest.GroupKey)
        ? $"{quest.Type}:{quest.Category}:{quest.RequiredActivity}:{quest.ProgressMode}"
        : quest.GroupKey;

    private static QuestEntity? SelectPersonalVariant(
        List<QuestEntity> variants, QuestType type, IReadOnlyList<ActivityRecordDto> history)
    {
        var activity = variants[0].RequiredActivity?.ToString();
        if (activity != null && history.Count(h => h.Type.Equals(activity, StringComparison.OrdinalIgnoreCase)) < 2)
            return null;

        var relevant = activity is null
            ? history
            : history.Where(h => h.Type.Equals(activity, StringComparison.OrdinalIgnoreCase)).ToList();
        var capacity = EstimateCapacity(variants[0], type, relevant);
        var ordered = variants.OrderBy(q => q.TargetValue ?? 0).ToList();
        if (capacity <= 0) return ordered.FirstOrDefault();
        return ordered.LastOrDefault(q => (q.TargetValue ?? 0) <= capacity * 1.15)
            ?? ordered.FirstOrDefault();
    }

    private static double EstimateCapacity(
        QuestEntity quest, QuestType type, IReadOnlyList<ActivityRecordDto> history)
    {
        if (history.Count == 0 || IsGameTask(quest)) return 0;
        double Value(ActivityRecordDto h) => quest.Category switch
        {
            QuestCategory.Duration => h.DurationMinutes,
            QuestCategory.Calories => h.Calories,
            QuestCategory.Distance => h.DistanceKm,
            QuestCategory.Workouts => 1,
            _ => 0,
        };
        if (quest.ProgressMode == QuestProgressMode.SingleActivity)
            return Median(history.Select(Value).Where(v => v > 0));

        var buckets = history.GroupBy(h => type == QuestType.Daily
                ? h.LoggedAt.Date
                : h.LoggedAt.Date.AddDays(-(((int)h.LoggedAt.DayOfWeek + 6) % 7)))
            .Select(g => g.Sum(Value)).Where(v => v > 0);
        return Median(buckets);
    }

    private static double Median(IEnumerable<double> values)
    {
        var sorted = values.OrderBy(v => v).ToArray();
        if (sorted.Length == 0) return 0;
        var middle = sorted.Length / 2;
        return sorted.Length % 2 == 0 ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle];
    }

    public async Task<TaskRewardPeriodDto> GetRewardPeriodAsync(Guid userId, QuestType type)
    {
        if (type is not (QuestType.Daily or QuestType.Weekly)) throw new ArgumentOutOfRangeException(nameof(type));
        await GeneratePeriodTasksAsync(userId, type);
        var now = DateTime.UtcNow;
        var (periodStart, resetAt) = PeriodBounds(type, now);
        var tasks = await db.Set<UserQuestProgressEntity>().Include(p => p.Quest)
            .Where(p => p.UserId == userId && p.Quest.Type == type && p.ExpiresAt > now)
            .OrderBy(p => p.Quest.SortOrder).ToListAsync();
        var maximum = type == QuestType.Daily ? 100 : 200;
        var points = Math.Min(tasks.Where(p => p.IsCompleted && p.RewardClaimed)
            .Sum(p => p.RewardPoints), maximum);
        var claimed = await db.Set<TaskRewardMilestoneClaim>()
            .Where(c => c.UserId == userId && c.PeriodType == type && c.PeriodStartUtc == periodStart)
            .Select(c => c.Threshold).ToListAsync();
        var rewards = type == QuestType.Daily ? DailyMilestones : WeeklyMilestones;
        var milestones = rewards.Select(m => new TaskMilestoneDto(
            m.Key, m.Value, points >= m.Key, claimed.Contains(m.Key))).ToList();
        return new(type.ToString(), periodStart, resetAt, points, maximum, milestones,
            tasks.Select(MapToDto).ToList());
    }

    public async Task<TaskMilestoneClaimResult> ClaimMilestoneAsync(Guid userId, QuestType type, int threshold)
    {
        var rewards = type == QuestType.Daily ? DailyMilestones : type == QuestType.Weekly ? WeeklyMilestones : null;
        if (rewards is null || !rewards.TryGetValue(threshold, out var reward))
            throw new InvalidOperationException("Invalid reward milestone.");
        return await ClaimMilestoneInternalAsync(userId, type, threshold, reward);
    }

    public async Task<TaskRewardsClaimResult> ClaimAvailableTaskRewardsAsync(
        Guid userId, QuestType type, CancellationToken ct = default)
    {
        if (type is not (QuestType.Daily or QuestType.Weekly))
            throw new InvalidOperationException("Period must be daily or weekly.");

        await GeneratePeriodTasksAsync(userId, type);
        var now = DateTime.UtcNow;
        var claimable = await db.Set<UserQuestProgressEntity>().Include(p => p.Quest)
            .Where(p => p.UserId == userId && p.Quest.Type == type &&
                        p.ExpiresAt > now && p.IsCompleted && !p.RewardClaimed)
            .OrderBy(p => p.Quest.SortOrder)
            .ToListAsync(ct);

        if (claimable.Count == 0)
            throw new InvalidOperationException(
                $"No completed {type.ToString().ToLowerInvariant()} tasks are ready to claim.");

        var coins = claimable.Sum(p => p.RewardCoins);
        var crystals = claimable.Sum(p => p.RewardCrystals);
        foreach (var task in claimable) task.RewardClaimed = true;
        await db.SaveChangesAsync(ct);

        if (rewardCurrency != null)
        {
            await rewardCurrency.AddCoinsAsync(userId, coins, ct);
            await rewardCurrency.AddCrystalsAsync(userId, crystals, ct);
        }

        return new(type.ToString(), claimable.Count, coins, crystals,
            await GetRewardPeriodAsync(userId, type));
    }

    /// <summary>
    /// Claims every milestone the player has reached but not yet claimed for
    /// the period, in threshold order — one tap collects everything owed
    /// instead of requiring a tap per tier. Mirrors
    /// <see cref="LifeLevel.Modules.Seasons.Application.UseCases.SeasonService.ClaimAvailableAsync"/>.
    /// </summary>
    public async Task<IReadOnlyList<TaskMilestoneClaimResult>> ClaimAvailableMilestonesAsync(
        Guid userId, QuestType type)
    {
        var rewards = type == QuestType.Daily ? DailyMilestones : type == QuestType.Weekly ? WeeklyMilestones : null;
        if (rewards is null) throw new InvalidOperationException("Period must be daily or weekly.");

        var results = new List<TaskMilestoneClaimResult>();
        foreach (var threshold in rewards.Keys.OrderBy(t => t))
        {
            var period = await GetRewardPeriodAsync(userId, type);
            var milestone = period.Milestones.FirstOrDefault(m => m.Threshold == threshold);
            if (milestone is null || !milestone.IsUnlocked || milestone.IsClaimed) continue;
            results.Add(await ClaimMilestoneInternalAsync(userId, type, threshold, rewards[threshold]));
        }

        if (results.Count == 0)
            throw new InvalidOperationException(
                $"No {type.ToString().ToLowerInvariant()} reward milestones are ready to claim.");

        return results;
    }

    private async Task<TaskMilestoneClaimResult> ClaimMilestoneInternalAsync(
        Guid userId, QuestType type, int threshold, TaskMilestoneRewardDto reward)
    {
        var period = await GetRewardPeriodAsync(userId, type);
        if (period.PointsEarned < threshold) throw new InvalidOperationException("This reward milestone is still locked.");
        if (await db.Set<TaskRewardMilestoneClaim>().AnyAsync(c => c.UserId == userId &&
            c.PeriodType == type && c.PeriodStartUtc == period.PeriodStartUtc && c.Threshold == threshold))
            throw new InvalidOperationException("This reward milestone was already claimed.");

        db.Set<TaskRewardMilestoneClaim>().Add(new()
        {
            UserId = userId, PeriodType = type, PeriodStartUtc = period.PeriodStartUtc,
            Threshold = threshold, ClaimedAtUtc = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
        if (rewardCurrency != null)
        {
            await rewardCurrency.AddCoinsAsync(userId, reward.Coins);
            await rewardCurrency.AddCrystalsAsync(userId, reward.Crystals);
        }
        if (reward.Xp > 0)
        {
            var result = await characterXp.AwardXpAsync(userId, "TaskMilestone", "🏅",
                $"{type} task milestone: {threshold} points", reward.Xp);
            await GrantLevelItemsIfNeededAsync(userId, result);
        }
        if (reward.Shields > 0 && streakShield != null)
            for (var i = 0; i < reward.Shields; i++) await streakShield.AddShieldAsync(userId);
        return new(type.ToString(), threshold, reward, await GetRewardPeriodAsync(userId, type));
    }

    public async Task<QuestProgressUpdateResult> UpdateProgressFromActivityAsync(
        Guid userId, ActivityType activityType, int durationMinutes, double? distanceKm, int? calories)
    {
        var now = DateTime.UtcNow;
        var active = await db.Set<UserQuestProgressEntity>().Include(p => p.Quest)
            .Where(p => p.UserId == userId && !p.IsCompleted &&
                        (p.ExpiresAt > now || p.ExpiresAt == SpecialQuestExpiry)).ToListAsync();
        var completed = new List<UserQuestProgressEntity>();
        foreach (var progress in active)
        {
            var task = progress.Quest;
            if (task.RequiredActivity.HasValue && task.RequiredActivity.Value != activityType) continue;
            var delta = task.Category switch
            {
                QuestCategory.Duration => durationMinutes,
                QuestCategory.Calories => calories ?? 0,
                QuestCategory.Distance => distanceKm ?? 0,
                QuestCategory.Workouts => 1,
                _ => 0,
            };
            if (delta <= 0) continue;
            progress.CurrentValue = task.ProgressMode == QuestProgressMode.SingleActivity
                ? Math.Max(progress.CurrentValue, delta)
                : progress.CurrentValue + delta;
            if (progress.CurrentValue < (task.TargetValue ?? 0)) continue;
            progress.IsCompleted = true;
            progress.CompletedAt = now;
            await db.SaveChangesAsync();

            long awardedXp = 0;
            if (task.Type == QuestType.Special && task.RewardXp > 0)
            {
                progress.RewardClaimed = true;
                awardedXp = await ApplyQuestXpTalentAsync(userId, task.RewardXp);
                var xp = await characterXp.AwardXpAsync(userId, "Quest", "🎯", $"Quest complete: {task.Title}", awardedXp);
                await GrantLevelItemsIfNeededAsync(userId, xp);
            }
            await events.PublishAsync(new QuestCompletedEvent(userId, task.Id, task.Title, awardedXp));
            completed.Add(progress);
        }
        await db.SaveChangesAsync();
        return new() { UpdatedQuests = completed.Select(MapToDto).ToList() };
    }

    public async Task UpdateProgressFromGameEventAsync(
        Guid userId, QuestCategory category, double delta = 1, CancellationToken ct = default)
    {
        if (delta <= 0) return;
        var now = DateTime.UtcNow;
        var active = await db.Set<UserQuestProgressEntity>().Include(p => p.Quest)
            .Where(p => p.UserId == userId && !p.IsCompleted && p.ExpiresAt > now &&
                        p.Quest.Category == category)
            .ToListAsync(ct);

        foreach (var progress in active)
        {
            progress.CurrentValue += delta;
            if (progress.CurrentValue < (progress.Quest.TargetValue ?? 0)) continue;
            progress.IsCompleted = true;
            progress.CompletedAt = now;
            await events.PublishAsync(new QuestCompletedEvent(
                userId, progress.Quest.Id, progress.Quest.Title, 0), ct);
        }
        await db.SaveChangesAsync(ct);
    }

    public Task ExpireStaleQuestsAsync() => Task.CompletedTask;

    public Task<int> CountCompletedDailyQuestsAsync(Guid userId, CancellationToken ct = default) =>
        db.Set<UserQuestProgressEntity>().CountAsync(p => p.UserId == userId && p.Quest.Type == QuestType.Daily &&
            p.IsCompleted && p.ExpiresAt > DateTime.UtcNow, ct);

    async Task<QuestActivityResult> IQuestProgressPort.UpdateProgressFromActivityAsync(
        Guid userId, ActivityType activityType, int durationMinutes, double? distanceKm, int? calories, CancellationToken ct)
    {
        var result = await UpdateProgressFromActivityAsync(userId, activityType, durationMinutes, distanceKm, calories);
        return new(result.UpdatedQuests.Select(q => new CompletedQuestInfo(q.QuestId, q.Title,
            (int)q.RewardXp, q.Description, q.Category, q.TargetValue, q.TargetUnit, q.Type)).ToList(), false, 0);
    }

    public async Task EnsureSpecialQuestsAsync(Guid userId)
    {
        if (await db.Set<UserQuestProgressEntity>().AnyAsync(p => p.UserId == userId && p.Quest.Type == QuestType.Special)) return;
        var tasks = await db.Set<QuestEntity>().Where(q => q.IsActive && q.Type == QuestType.Special).ToListAsync();
        foreach (var task in tasks) db.Set<UserQuestProgressEntity>().Add(new()
        {
            UserId = userId, QuestId = task.Id, AssignedAt = DateTime.UtcNow, ExpiresAt = SpecialQuestExpiry,
        });
        await db.SaveChangesAsync();
    }

    private async Task<long> ApplyQuestXpTalentAsync(Guid userId, long baseXp)
    {
        if (talentBonus is null) return baseXp;
        var pct = (await talentBonus.GetBonusesAsync(userId)).QuestXpPct;
        return pct <= 0 ? baseXp : (long)Math.Round(baseXp * (1 + pct / 100.0));
    }

    private static (DateTime Start, DateTime Reset) PeriodBounds(QuestType type, DateTime utcNow)
    {
        if (type == QuestType.Daily) return (utcNow.Date, utcNow.Date.AddDays(1));
        var daysSinceMonday = ((int)utcNow.DayOfWeek + 6) % 7;
        var start = utcNow.Date.AddDays(-daysSinceMonday);
        return (start, start.AddDays(7));
    }

    private async Task GrantLevelItemsIfNeededAsync(Guid userId, XpAwardResult result)
    {
        if (result.LeveledUp)
            await levelUpItemGrant.EvaluateAndGrantAsync(userId, result.PreviousLevel, result.NewLevel);
    }

    private static UserQuestProgressDto MapToDto(UserQuestProgressEntity p) => new()
    {
        Id = p.Id, QuestId = p.QuestId, Title = p.Quest.Title, Description = p.Quest.Description,
        Type = p.Quest.Type.ToString(), Category = p.Quest.Category.ToString(),
        ProgressMode = p.Quest.ProgressMode.ToString(), DifficultyTier = p.Quest.DifficultyTier.ToString(),
        RequiredActivity = p.Quest.RequiredActivity?.ToString(), TargetValue = p.Quest.TargetValue ?? 0,
        CurrentValue = p.CurrentValue, TargetUnit = p.Quest.TargetUnit, RewardXp = p.Quest.RewardXp,
        RewardCoins = p.RewardCoins, RewardCrystals = p.RewardCrystals, RewardPoints = p.RewardPoints,
        IsCompleted = p.IsCompleted, RewardClaimed = p.RewardClaimed,
        ExpiresAt = p.ExpiresAt, CompletedAt = p.CompletedAt,
    };
}
