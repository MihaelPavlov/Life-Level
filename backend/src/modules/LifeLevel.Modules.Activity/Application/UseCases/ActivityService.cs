using LifeLevel.Modules.Activity.Application.DTOs;
using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ActivityEntity = LifeLevel.Modules.Activity.Domain.Entities.Activity;

namespace LifeLevel.Modules.Activity.Application.UseCases;

public class ActivityService(
    DbContext db,
    ICharacterXpPort characterXp,
    ICharacterStatPort characterStats,
    ICharacterIdReadPort characterIdRead,
    IEventPublisher events,
    IStreakReadPort streakRead,
    IQuestProgressPort questProgress,
    IMapDistancePort mapDistance,
    IWorldZoneDistancePort worldZoneDistance,
    IGearBonusReadPort gearBonus,
    ILevelUpItemGrantPort levelUpItemGrant,
    IZoneUnlockReadPort zoneUnlockRead,
    ICharacterTutorialPort characterTutorial,
    ILogger<ActivityService> logger)
    : IActivityStatsReadPort, IActivityLogPort, IActivityExternalIdReadPort
{
    // LL-035: the "log your first activity" tutorial step gate. We advance the character
    // from step 4 → 5 only when the user actually logs a real activity (port-driven).
    private const int TutorialActivityGateStep = 4;

    private async Task TryAdvanceTutorialAsync(Guid characterId, CancellationToken ct = default)
    {
        try
        {
            await characterTutorial.AdvanceIfOnStepAsync(characterId, TutorialActivityGateStep, ct);
        }
        catch (Exception ex)
        {
            // Tutorial advancement must never break activity logging.
            logger.LogWarning(ex, "Tutorial advance failed for character {CharacterId}; activity log succeeded.", characterId);
        }
    }

    public async Task<LogActivityResult> LogActivityAsync(Guid userId, LogActivityRequest request)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId)
            ?? throw new InvalidOperationException("Character not found.");

        var (xp, str, end, agi, flx, sta) = CalculateGains(request);

        // Apply gear XP bonus
        var gearBonuses = await gearBonus.GetEquippedBonusesAsync(userId);
        int xpBonusApplied = 0;
        if (gearBonuses.XpBonusPct > 0)
        {
            var boostedXp = (int)(xp * (1.0 + gearBonuses.XpBonusPct / 100.0));
            xpBonusApplied = boostedXp - xp;
            xp = boostedXp;
        }

        var activity = new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = characterId,
            Type = request.Type,
            DurationMinutes = request.DurationMinutes,
            DistanceKm = request.DistanceKm ?? 0,
            Calories = request.Calories ?? 0,
            HeartRateAvg = request.HeartRateAvg,
            XpGained = xp,
            StrGained = str,
            EndGained = end,
            AgiGained = agi,
            FlxGained = flx,
            StaGained = sta,
            Steps = CalculateSteps(request.Type, request.DistanceKm ?? 0),
            LoggedAt = DateTime.UtcNow,
        };
        db.Set<ActivityEntity>().Add(activity);
        await db.SaveChangesAsync();

        // Apply stat gains and award XP via ports
        await characterStats.ApplyStatGainsAsync(userId, new StatGains(str, end, agi, flx, sta));
        var xpResult = await characterXp.AwardXpAsync(userId, "Activity", GetActivityEmoji(request.Type),
            $"{request.Type} workout · {request.DurationMinutes} min", xp);

        // Publish event for other listeners (streak, etc.)
        await events.PublishAsync(new ActivityLoggedEvent(
            userId, activity.Id, request.Type, request.DurationMinutes,
            request.DistanceKm ?? 0, request.Calories ?? 0));

        if (request.DistanceKm > 0)
        {
            logger.LogInformation("ActivityService.LogActivity user={UserId} type={Type} incomingDistanceKm={Km}",
                userId, request.Type, request.DistanceKm);
            // MapService.DebugAddDistanceAsync now cascades the same km to the
            // world-zone port, so a single call advances both systems.
            await mapDistance.AddDistanceAsync(userId, request.DistanceKm ?? 0);
        }

        // Update quest progress and capture which quests were just completed
        var questResult = await questProgress.UpdateProgressFromActivityAsync(
            userId, request.Type, request.DurationMinutes,
            request.DistanceKm, request.Calories);

        // Read back streak state for response
        var streak = await streakRead.GetCurrentStreakAsync(userId);

        LevelUpUnlocksDto? levelUpUnlocks = null;
        if (xpResult.LeveledUp)
        {
            var grantedItems = await levelUpItemGrant.EvaluateAndGrantAsync(
                userId, xpResult.PreviousLevel, xpResult.NewLevel);
            var unlockedZones = await zoneUnlockRead.GetZonesUnlockedInRangeAsync(
                xpResult.PreviousLevel, xpResult.NewLevel);
            levelUpUnlocks = new LevelUpUnlocksDto(
                StatPointsGained: xpResult.NewLevel - xpResult.PreviousLevel,
                GrantedItems: grantedItems,
                UnlockedZones: unlockedZones);
        }

        return new LogActivityResult
        {
            ActivityId = activity.Id,
            XpGained = xp,
            StrGained = str,
            EndGained = end,
            AgiGained = agi,
            FlxGained = flx,
            StaGained = sta,
            LeveledUp = xpResult.LeveledUp,
            NewLevel = xpResult.LeveledUp ? xpResult.NewLevel : null,
            CompletedQuests = questResult.CompletedQuests,
            StreakUpdated = streak != null,
            CurrentStreak = streak?.Current ?? 0,
            AllDailyQuestsCompleted = questResult.AllDailyCompleted,
            BonusXpAwarded = questResult.BonusXp,
            XpBonusApplied = xpBonusApplied,
            LevelUpUnlocks = levelUpUnlocks,
        };
    }

    public async Task<ActivityLogPortResult> LogExternalActivityAsync(
        Guid userId, ActivityType type, int durationMinutes, double? distanceKm,
        int? calories, int? heartRateAvg, string externalId, DateTime performedAt,
        CancellationToken ct = default)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct)
            ?? throw new InvalidOperationException("Character not found.");

        var req = new LogActivityRequest
        {
            Type = type,
            DurationMinutes = durationMinutes,
            DistanceKm = distanceKm,
            Calories = calories,
            HeartRateAvg = heartRateAvg,
        };
        var (xp, str, end, agi, flx, sta) = CalculateGains(req);

        var activity = new ActivityEntity
        {
            Id = Guid.NewGuid(),
            CharacterId = characterId,
            Type = type,
            DurationMinutes = durationMinutes,
            DistanceKm = distanceKm ?? 0,
            Calories = calories ?? 0,
            HeartRateAvg = heartRateAvg,
            XpGained = xp,
            StrGained = str,
            EndGained = end,
            AgiGained = agi,
            FlxGained = flx,
            StaGained = sta,
            Steps = CalculateSteps(type, distanceKm ?? 0),
            ExternalId = externalId,
            LoggedAt = performedAt,
        };
        db.Set<ActivityEntity>().Add(activity);
        await db.SaveChangesAsync(ct);

        await characterStats.ApplyStatGainsAsync(userId, new StatGains(str, end, agi, flx, sta));
        await characterXp.AwardXpAsync(userId, "Activity", GetActivityEmoji(type),
            $"{type} workout · {durationMinutes} min", xp);

        await events.PublishAsync(new ActivityLoggedEvent(
            userId, activity.Id, type, durationMinutes,
            distanceKm ?? 0, calories ?? 0));

        if (distanceKm > 0)
        {
            logger.LogInformation("ActivityService.LogExternalActivity user={UserId} type={Type} incomingDistanceKm={Km} externalId={ExternalId}",
                userId, type, distanceKm, externalId);
            // MapService cascades to world-zone; one call advances both.
            await mapDistance.AddDistanceAsync(userId, distanceKm ?? 0, ct);
        }

        await questProgress.UpdateProgressFromActivityAsync(
            userId, type, durationMinutes, distanceKm, calories);

        return new ActivityLogPortResult(activity.Id, xp);
    }

    public async Task<List<ActivityHistoryDto>> GetHistoryAsync(Guid userId)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId);
        if (characterId == null) return [];

        return await db.Set<ActivityEntity>()
            .Where(a => a.CharacterId == characterId)
            .OrderByDescending(a => a.LoggedAt)
            .Take(20)
            .Select(a => new ActivityHistoryDto
            {
                Id = a.Id,
                Type = a.Type.ToString(),
                DurationMinutes = a.DurationMinutes,
                DistanceKm = a.DistanceKm,
                Calories = a.Calories,
                HeartRateAvg = a.HeartRateAvg,
                XpGained = a.XpGained,
                StrGained = a.StrGained,
                EndGained = a.EndGained,
                AgiGained = a.AgiGained,
                FlxGained = a.FlxGained,
                StaGained = a.StaGained,
                Steps = a.Steps,
                LoggedAt = a.LoggedAt,
            })
            .ToListAsync();
    }

    // IActivityStatsReadPort
    public async Task<WeeklyActivityStatsDto> GetWeeklyStatsAsync(Guid userId, CancellationToken ct = default)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId, ct);
        if (characterId == null)
            return new WeeklyActivityStatsDto(0, 0, 0);

        var weekStart = DateTime.UtcNow.Date.AddDays(-(int)DateTime.UtcNow.DayOfWeek);
        var activities = await db.Set<ActivityEntity>()
            .Where(a => a.CharacterId == characterId && a.LoggedAt >= weekStart)
            .Select(a => new { a.Type, a.DistanceKm, a.XpGained })
            .ToListAsync(ct);

        return new WeeklyActivityStatsDto(
            WeeklyRuns: activities.Count(a => a.Type == ActivityType.Running),
            WeeklyDistanceKm: activities.Sum(a => a.DistanceKm),
            WeeklyXpEarned: activities.Sum(a => a.XpGained)
        );
    }

    // IActivityExternalIdReadPort
    public async Task<Guid?> FindActivityIdByExternalIdAsync(Guid characterId, string externalId, CancellationToken ct = default)
    {
        return await db.Set<ActivityEntity>()
            .Where(a => a.CharacterId == characterId && a.ExternalId == externalId)
            .Select(a => (Guid?)a.Id)
            .FirstOrDefaultAsync(ct);
    }

    private static (int Xp, int Str, int End, int Agi, int Flx, int Sta) CalculateGains(LogActivityRequest req)
    {
        double baseXp = req.DurationMinutes * 3.0;
        int str = 0, end = 0, agi = 0, flx = 0, sta = 0;

        switch (req.Type)
        {
            case ActivityType.Running:   end = 2; agi = 1; baseXp *= 1.2; baseXp += (req.DistanceKm ?? 0) * 10; break;
            case ActivityType.Cycling:   end = 2; agi = 1; baseXp *= 1.1; baseXp += (req.DistanceKm ?? 0) * 8;  break;
            case ActivityType.Gym:       str = 3; sta = 1; baseXp *= 1.0; break;
            case ActivityType.Yoga:      flx = 3; sta = 1; baseXp *= 0.8; break;
            case ActivityType.Swimming:  end = 2; sta = 2; baseXp *= 1.2; break;
            case ActivityType.Hiking:    end = 1; sta = 2; agi = 1; baseXp *= 1.0; baseXp += (req.DistanceKm ?? 0) * 6; break;
            case ActivityType.Walking:   end = 1; sta = 1;          baseXp *= 0.8; baseXp += (req.DistanceKm ?? 0) * 5; break;
            case ActivityType.Climbing:  str = 2; end = 1; agi = 1; baseXp *= 1.3; break;
        }

        if (req.Calories.HasValue && req.Calories.Value > 0)
            baseXp += req.Calories.Value / 10.0;

        return ((int)Math.Round(baseXp), str, end, agi, flx, sta);
    }

    private static int CalculateSteps(ActivityType type, double distanceKm) =>
        type switch
        {
            ActivityType.Running or ActivityType.Hiking or ActivityType.Walking or ActivityType.Cycling
                => (int)(distanceKm * 1250),
            _ => 0
        };

    private static string GetActivityEmoji(ActivityType type) => type switch
    {
        ActivityType.Running  => "🏃",
        ActivityType.Cycling  => "🚴",
        ActivityType.Gym      => "💪",
        ActivityType.Yoga     => "🧘",
        ActivityType.Swimming => "🏊",
        ActivityType.Hiking   => "🥾",
        ActivityType.Walking  => "🚶",
        ActivityType.Climbing => "🧗",
        _ => "🏋️",
    };
}
