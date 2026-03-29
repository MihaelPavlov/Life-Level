using LifeLevel.Api.Application.DTOs.Activity;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Domain.Enums;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class ActivityService(
    AppDbContext db,
    CharacterService characterService,
    StreakService streakService,
    QuestService questService)
{
    public async Task<LogActivityResult> LogActivityAsync(Guid userId, LogActivityRequest request)
    {
        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        var (xp, str, end, agi, flx, sta) = CalculateGains(request);

        // Save Activity entity
        var activity = new Activity
        {
            Id = Guid.NewGuid(),
            CharacterId = character.Id,
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
            LoggedAt = DateTime.UtcNow,
        };
        db.Activities.Add(activity);

        // Apply stat gains to character (cap at 100)
        character.Strength    = Math.Min(100, character.Strength    + str);
        character.Endurance   = Math.Min(100, character.Endurance   + end);
        character.Agility     = Math.Min(100, character.Agility     + agi);
        character.Flexibility = Math.Min(100, character.Flexibility + flx);
        character.Stamina     = Math.Min(100, character.Stamina     + sta);

        // Apply XP to character
        character.Xp += xp;
        character.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();

        // Record XP history entry (also calls level-up internally)
        await characterService.RecordXpAsync(
            character,
            "Activity",
            GetActivityEmoji(request.Type),
            $"{request.Type} workout · {request.DurationMinutes} min",
            xp);

        // Update streak
        var streakResult = await streakService.RecordActivityDayAsync(userId, DateTime.UtcNow.Date);

        // Update quest progress
        var questResult = await questService.UpdateProgressFromActivityAsync(userId, request);

        // Final level-up check (quest XP may have pushed further)
        var (leveledUp, newLevel) = await characterService.CheckAndApplyLevelUpsAsync(character.Id);

        // Get current streak count
        var streak = await streakService.GetOrCreateAsync(userId);

        return new LogActivityResult
        {
            ActivityId = activity.Id,
            XpGained = xp,
            StrGained = str,
            EndGained = end,
            AgiGained = agi,
            FlxGained = flx,
            StaGained = sta,
            LeveledUp = leveledUp,
            NewLevel = leveledUp ? newLevel : null,
            CompletedQuests = questResult.UpdatedQuests,
            StreakUpdated = streakResult.Updated,
            CurrentStreak = streak.Current,
            AllDailyQuestsCompleted = questResult.AllDailyCompleted,
            BonusXpAwarded = questResult.BonusXpAwarded,
        };
    }

    public async Task<List<ActivityHistoryDto>> GetHistoryAsync(Guid userId)
    {
        var character = await db.Characters
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (character == null) return [];

        return await db.Activities
            .Where(a => a.CharacterId == character.Id)
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
                LoggedAt = a.LoggedAt,
            })
            .ToListAsync();
    }

    // ── Private helpers ────────────────────────────────────────────────────────

    private static (int Xp, int Str, int End, int Agi, int Flx, int Sta) CalculateGains(LogActivityRequest req)
    {
        double baseXp = req.DurationMinutes * 3.0;
        int str = 0, end = 0, agi = 0, flx = 0, sta = 0;

        switch (req.Type)
        {
            case ActivityType.Running:
                end = 2; agi = 1;
                baseXp *= 1.2;
                baseXp += (req.DistanceKm ?? 0) * 10;
                break;
            case ActivityType.Cycling:
                end = 2; agi = 1;
                baseXp *= 1.1;
                baseXp += (req.DistanceKm ?? 0) * 8;
                break;
            case ActivityType.Gym:
                str = 3; sta = 1;
                baseXp *= 1.0;
                break;
            case ActivityType.Yoga:
                flx = 3; sta = 1;
                baseXp *= 0.8;
                break;
            case ActivityType.Swimming:
                end = 2; sta = 2;
                baseXp *= 1.2;
                break;
            case ActivityType.Hiking:
                end = 1; sta = 2; agi = 1;
                baseXp *= 1.0;
                baseXp += (req.DistanceKm ?? 0) * 6;
                break;
            case ActivityType.Climbing:
                str = 2; end = 1; agi = 1;
                baseXp *= 1.3;
                break;
        }

        // Calories bonus
        if (req.Calories.HasValue && req.Calories.Value > 0)
            baseXp += req.Calories.Value / 10.0;

        var xp = (int)Math.Round(baseXp);
        return (xp, str, end, agi, flx, sta);
    }

    private static string GetActivityEmoji(ActivityType type) => type switch
    {
        ActivityType.Running  => "🏃",
        ActivityType.Cycling  => "🚴",
        ActivityType.Gym      => "💪",
        ActivityType.Yoga     => "🧘",
        ActivityType.Swimming => "🏊",
        ActivityType.Hiking   => "🥾",
        ActivityType.Climbing => "🧗",
        _ => "🏋️",
    };
}
