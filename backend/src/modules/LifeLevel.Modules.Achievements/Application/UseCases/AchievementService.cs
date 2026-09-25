using LifeLevel.Modules.Achievements.Application.DTOs;
using LifeLevel.Modules.Achievements.Domain;
using LifeLevel.Modules.Achievements.Domain.Entities;
using LifeLevel.Modules.Achievements.Domain.Enums;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using ActivityEntity = LifeLevel.Modules.Activity.Domain.Entities.Activity;
using StreakEntity = LifeLevel.Modules.Streak.Domain.Entities.Streak;

namespace LifeLevel.Modules.Achievements.Application.UseCases;

/// <summary>
/// Achievements and Reward Roads. Unlocking an achievement only records it; the
/// player claims it to receive XP, coins and gems. Each road (category) is split into
/// stages by tier, and a stage's chest opens once every achievement in it is claimed.
/// </summary>
public class AchievementService(
    DbContext db,
    ICharacterXpPort xp,
    ICharacterIdReadPort charId,
    IRewardCurrencyPort currency,
    IShopWalletPort wallet,
    IChestItemRewardPort chestItems)
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
            return ToDto(a, ua);
        }).ToList();

        return dtos
            .OrderByDescending(d => d.IsUnlocked ? 1 : 0)
            .ThenByDescending(d => d.UnlockedAt)
            .ThenByDescending(d => d.TargetValue > 0 ? d.CurrentValue / d.TargetValue : 0)
            .ThenBy(d => d.Title)
            .ToList();
    }

    /// <summary>Refreshes progress and records new unlocks. Pays nothing — rewards are claimed.</summary>
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
        var values = new Dictionary<ConditionType, double>();

        foreach (var achievement in achievements)
        {
            if (!values.TryGetValue(achievement.ConditionType, out var currentValue))
            {
                currentValue = await ComputeConditionValueAsync(
                    userId, characterId.Value, achievement.ConditionType, ct);
                values[achievement.ConditionType] = currentValue;
            }

            if (!progressDict.TryGetValue(achievement.Id, out var ua))
            {
                ua = new UserAchievement { UserId = userId, AchievementId = achievement.Id };
                db.Set<UserAchievement>().Add(ua);
            }

            ua.CurrentValue = currentValue;
            if (!ua.IsUnlocked && currentValue >= achievement.TargetValue)
            {
                ua.UnlockedAt = DateTime.UtcNow;
                newlyUnlocked.Add(achievement.Id);
            }
        }

        await db.SaveChangesAsync(ct);
        return new CheckUnlocksResult(newlyUnlocked);
    }

    // ── Reward Roads ─────────────────────────────────────────────────────────

    public async Task<AchievementRoadsResponse> GetRoadsAsync(Guid userId, CancellationToken ct = default)
    {
        await CheckUnlocksAsync(userId, ct);

        var achievements = await db.Set<Achievement>().ToListAsync(ct);
        var progress = await db.Set<UserAchievement>()
            .Where(u => u.UserId == userId)
            .ToDictionaryAsync(u => u.AchievementId, ct);
        var opened = await OpenedStagesAsync(userId, ct);

        var roads = Enum.GetValues<AchievementCategory>()
            .Select(category => BuildRoad(category, achievements, progress, opened))
            .Where(r => r.Total > 0)
            .ToList();

        return new AchievementRoadsResponse(
            await WalletAsync(userId, ct),
            roads.Sum(r => r.Ready),
            roads.Sum(r => r.Stages.Count(s => s.ChestReady)),
            roads);
    }

    /// <summary>Claims the given unlocked, unclaimed achievements (already-claimed ids are skipped).</summary>
    public async Task<AchievementClaimResult> ClaimAsync(
        Guid userId, IReadOnlyCollection<Guid> achievementIds, CancellationToken ct = default)
    {
        var rows = await db.Set<UserAchievement>()
            .Include(u => u.Achievement)
            .Where(u => u.UserId == userId && achievementIds.Contains(u.AchievementId))
            .ToListAsync(ct);
        return await ClaimRowsAsync(userId, rows, ct);
    }

    /// <summary>Claims every ready achievement, optionally only in one category.</summary>
    public async Task<AchievementClaimResult> ClaimAllAsync(
        Guid userId, string? category, CancellationToken ct = default)
    {
        await CheckUnlocksAsync(userId, ct);
        var query = db.Set<UserAchievement>()
            .Include(u => u.Achievement)
            .Where(u => u.UserId == userId && u.UnlockedAt != null && u.ClaimedAt == null);
        if (!string.IsNullOrWhiteSpace(category))
        {
            var cat = ParseCategory(category);
            query = query.Where(u => u.Achievement.Category == cat);
        }
        return await ClaimRowsAsync(userId, await query.ToListAsync(ct), ct);
    }

    public async Task<StageChestOpenResult> OpenStageChestAsync(
        Guid userId, string category, string tier, CancellationToken ct = default)
    {
        var cat = ParseCategory(category);
        if (!Enum.TryParse<AchievementTier>(tier, true, out var t))
            throw new AchievementException("stage_not_found", "That stage does not exist.");

        var stageIds = await db.Set<Achievement>()
            .Where(a => a.Category == cat && a.Tier == t)
            .Select(a => a.Id)
            .ToListAsync(ct);
        if (stageIds.Count == 0)
            throw new AchievementException("stage_not_found", "That stage does not exist.");

        var claimed = await db.Set<UserAchievement>()
            .CountAsync(u => u.UserId == userId && stageIds.Contains(u.AchievementId) && u.ClaimedAt != null, ct);
        if (claimed < stageIds.Count)
            throw new AchievementException("stage_not_complete", "Claim every achievement in this stage first.");

        if (await db.Set<UserAchievementStageChest>()
                .AnyAsync(c => c.UserId == userId && c.Category == cat && c.Tier == t, ct))
            throw new AchievementException("chest_already_opened", "This chest is already open.");

        // Record the opening before paying out; the unique (user, category, tier) index
        // rejects a second, concurrent open.
        var chest = AchievementRewardTable.Chest(t);
        var row = new UserAchievementStageChest
        {
            UserId = userId, Category = cat, Tier = t, OpenedAt = DateTime.UtcNow,
            Coins = chest.Coins, Gems = chest.Gems,
        };
        db.Set<UserAchievementStageChest>().Add(row);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            throw new AchievementException("chest_already_opened", "This chest is already open.");
        }

        var item = await chestItems.GrantRandomUnownedAsync(userId, chest.ItemRarity, ct);
        row.ItemId = item?.ItemId;
        if (chest.Coins > 0) await currency.AddCoinsAsync(userId, chest.Coins, ct);
        if (chest.Gems > 0) await currency.AddCrystalsAsync(userId, chest.Gems, ct);
        await db.SaveChangesAsync(ct);

        return new StageChestOpenResult(
            cat.ToString(), t.ToString(), chest.Key, chest.Name,
            item == null ? null : new StageChestItemDto(item.ItemId, item.Name, item.Icon, item.Rarity, item.InventoryIconUrl),
            chest.Coins, chest.Gems,
            await WalletAsync(userId, ct));
    }

    private async Task<AchievementClaimResult> ClaimRowsAsync(
        Guid userId, List<UserAchievement> rows, CancellationToken ct)
    {
        var claimable = rows.Where(u => u.IsUnlocked && !u.IsClaimed).ToList();
        long xpTotal = 0;
        int coins = 0, gems = 0;
        var now = DateTime.UtcNow;

        foreach (var ua in claimable)
        {
            ua.ClaimedAt = now;
            xpTotal += ua.Achievement.XpReward;
            coins += ua.Achievement.CoinReward;
            gems += ua.Achievement.GemReward;
        }
        await db.SaveChangesAsync(ct);

        foreach (var ua in claimable)
        {
            await xp.AwardXpAsync(userId, "Achievement", ua.Achievement.Icon,
                ua.Achievement.Title, ua.Achievement.XpReward, ct);
        }
        if (coins > 0) await currency.AddCoinsAsync(userId, coins, ct);
        if (gems > 0) await currency.AddCrystalsAsync(userId, gems, ct);

        // Stages this claim finished whose chest is still closed.
        var chestsReady = new List<AchievementStageKeyDto>();
        if (claimable.Count > 0)
        {
            var achievements = await db.Set<Achievement>().ToListAsync(ct);
            var progress = await db.Set<UserAchievement>()
                .Where(u => u.UserId == userId)
                .ToDictionaryAsync(u => u.AchievementId, ct);
            var opened = await OpenedStagesAsync(userId, ct);
            foreach (var (cat, tier) in claimable.Select(u => (u.Achievement.Category, u.Achievement.Tier)).Distinct())
            {
                var stage = achievements.Where(a => a.Category == cat && a.Tier == tier).ToList();
                var allClaimed = stage.All(a => progress.TryGetValue(a.Id, out var p) && p.IsClaimed);
                if (allClaimed && !opened.Contains((cat, tier)))
                    chestsReady.Add(new AchievementStageKeyDto(cat.ToString(), tier.ToString()));
            }
        }

        return new AchievementClaimResult(
            claimable.Select(u => u.AchievementId).ToList(),
            xpTotal, coins, gems, chestsReady,
            await WalletAsync(userId, ct));
    }

    private static AchievementRoadDto BuildRoad(
        AchievementCategory category,
        List<Achievement> achievements,
        Dictionary<Guid, UserAchievement> progress,
        HashSet<(AchievementCategory, AchievementTier)> opened)
    {
        var stages = new List<AchievementStageDto>();
        foreach (var tier in Enum.GetValues<AchievementTier>())
        {
            var list = achievements.Where(a => a.Category == category && a.Tier == tier)
                .OrderBy(a => a.TargetValue).ThenBy(a => a.Title)
                .Select(a => ToDto(a, progress.GetValueOrDefault(a.Id)))
                .ToList();
            if (list.Count == 0) continue;

            var chest = AchievementRewardTable.Chest(tier);
            var claimed = list.Count(a => a.IsClaimed);
            var isOpened = opened.Contains((category, tier));
            stages.Add(new AchievementStageDto(
                tier.ToString(), chest.Key, chest.Name, chest.ItemRarity, chest.Coins, chest.Gems,
                list.Count,
                list.Count(a => a.IsUnlocked),
                claimed,
                list.Count(a => a.IsUnlocked && !a.IsClaimed),
                ChestReady: claimed == list.Count && !isOpened,
                ChestOpened: isOpened,
                list));
        }

        return new AchievementRoadDto(
            category.ToString(),
            stages.Sum(s => s.Total),
            stages.Sum(s => s.Claimed),
            stages.Sum(s => s.Ready),
            stages.FindIndex(s => !s.ChestOpened),
            stages);
    }

    private async Task<HashSet<(AchievementCategory, AchievementTier)>> OpenedStagesAsync(Guid userId, CancellationToken ct)
    {
        var rows = await db.Set<UserAchievementStageChest>()
            .Where(c => c.UserId == userId)
            .Select(c => new { c.Category, c.Tier })
            .ToListAsync(ct);
        return rows.Select(r => (r.Category, r.Tier)).ToHashSet();
    }

    private async Task<AchievementWalletDto> WalletAsync(Guid userId, CancellationToken ct)
    {
        var balance = await wallet.GetBalanceAsync(userId, ct);
        return new AchievementWalletDto(balance.Coins, balance.Gems);
    }

    private static AchievementCategory ParseCategory(string category) =>
        Enum.TryParse<AchievementCategory>(category, true, out var cat)
            ? cat
            : throw new AchievementException("road_not_found", "That road does not exist.");

    private static AchievementDto ToDto(Achievement a, UserAchievement? ua) => new(
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
        ua?.UnlockedAt,
        a.CoinReward,
        a.GemReward,
        ua?.IsClaimed ?? false,
        ua?.ClaimedAt);

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
