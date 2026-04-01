using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Achievements.Domain.Entities;
using LifeLevel.Modules.Achievements.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class AchievementSeeder(AppDbContext db)
{
    private static readonly Achievement[] Catalog =
    [
        // ── Running (7) ────────────────────────────────────────────────────────
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000001"), Title = "First Steps", Description = "Log your very first activity.", Icon = "🥇", Category = AchievementCategory.Running, Tier = AchievementTier.Common, XpReward = 100, ConditionType = ConditionType.TotalActivities, TargetValue = 1, TargetUnit = "activity" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000002"), Title = "Road Warrior", Description = "Cover 10 km of running distance in total.", Icon = "🏃", Category = AchievementCategory.Running, Tier = AchievementTier.Uncommon, XpReward = 250, ConditionType = ConditionType.TotalRunningDistanceKm, TargetValue = 10, TargetUnit = "km" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000003"), Title = "Marathon Prep", Description = "Run a total of 42 km — marathon distance.", Icon = "🏅", Category = AchievementCategory.Running, Tier = AchievementTier.Rare, XpReward = 500, ConditionType = ConditionType.TotalRunningDistanceKm, TargetValue = 42, TargetUnit = "km" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000004"), Title = "Century Runner", Description = "Reach 100 km total running distance.", Icon = "💯", Category = AchievementCategory.Running, Tier = AchievementTier.Epic, XpReward = 1000, ConditionType = ConditionType.TotalRunningDistanceKm, TargetValue = 100, TargetUnit = "km" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000005"), Title = "Iron Legs", Description = "Run 500 km total lifetime distance.", Icon = "🦵", Category = AchievementCategory.Running, Tier = AchievementTier.Legendary, XpReward = 5000, ConditionType = ConditionType.TotalRunningDistanceKm, TargetValue = 500, TargetUnit = "km" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000006"), Title = "Consistent Mover", Description = "Log 10 activities of any type.", Icon = "📅", Category = AchievementCategory.Running, Tier = AchievementTier.Uncommon, XpReward = 300, ConditionType = ConditionType.TotalActivities, TargetValue = 10, TargetUnit = "activities" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000007"), Title = "Activity Machine", Description = "Log 50 activities of any type.", Icon = "⚙️", Category = AchievementCategory.Running, Tier = AchievementTier.Rare, XpReward = 750, ConditionType = ConditionType.TotalActivities, TargetValue = 50, TargetUnit = "activities" },

        // ── Strength (5) ───────────────────────────────────────────────────────
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000008"), Title = "First Rep", Description = "Log your first gym session.", Icon = "💪", Category = AchievementCategory.Strength, Tier = AchievementTier.Common, XpReward = 100, ConditionType = ConditionType.TotalGymActivities, TargetValue = 1, TargetUnit = "session" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000009"), Title = "Gym Rat", Description = "Complete 10 gym sessions.", Icon = "🏋️", Category = AchievementCategory.Strength, Tier = AchievementTier.Uncommon, XpReward = 250, ConditionType = ConditionType.TotalGymActivities, TargetValue = 10, TargetUnit = "sessions" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000010"), Title = "Iron Regular", Description = "Hit the gym 30 times.", Icon = "🏋️", Category = AchievementCategory.Strength, Tier = AchievementTier.Rare, XpReward = 600, ConditionType = ConditionType.TotalGymActivities, TargetValue = 30, TargetUnit = "sessions" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000011"), Title = "Gym Veteran", Description = "Complete 100 gym sessions.", Icon = "🥈", Category = AchievementCategory.Strength, Tier = AchievementTier.Epic, XpReward = 1500, ConditionType = ConditionType.TotalGymActivities, TargetValue = 100, TargetUnit = "sessions" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000012"), Title = "Centurion", Description = "Log 365 gym sessions — a full year of training.", Icon = "👑", Category = AchievementCategory.Strength, Tier = AchievementTier.Legendary, XpReward = 5000, ConditionType = ConditionType.TotalGymActivities, TargetValue = 365, TargetUnit = "sessions" },

        // ── Social / Streak (5) ────────────────────────────────────────────────
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000013"), Title = "On a Roll", Description = "Maintain a 3-day activity streak.", Icon = "🔥", Category = AchievementCategory.Social, Tier = AchievementTier.Common, XpReward = 100, ConditionType = ConditionType.CurrentStreakDays, TargetValue = 3, TargetUnit = "days" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000014"), Title = "Week Warrior", Description = "Maintain a 7-day streak.", Icon = "📆", Category = AchievementCategory.Social, Tier = AchievementTier.Uncommon, XpReward = 300, ConditionType = ConditionType.CurrentStreakDays, TargetValue = 7, TargetUnit = "days" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000015"), Title = "Dedicated", Description = "Reach a 30-day streak at any point.", Icon = "⭐", Category = AchievementCategory.Social, Tier = AchievementTier.Rare, XpReward = 750, ConditionType = ConditionType.MaxStreakDays, TargetValue = 30, TargetUnit = "days" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000016"), Title = "Unstoppable", Description = "Achieve a streak of 100 days.", Icon = "🌟", Category = AchievementCategory.Social, Tier = AchievementTier.Epic, XpReward = 2000, ConditionType = ConditionType.MaxStreakDays, TargetValue = 100, TargetUnit = "days" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000017"), Title = "Legend of Endurance", Description = "Sustain a 365-day streak — a full year.", Icon = "🏆", Category = AchievementCategory.Social, Tier = AchievementTier.Legendary, XpReward = 10000, ConditionType = ConditionType.MaxStreakDays, TargetValue = 365, TargetUnit = "days" },

        // ── Raids (5) ──────────────────────────────────────────────────────────
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000018"), Title = "Boss Hunter", Description = "Defeat your first boss.", Icon = "⚔️", Category = AchievementCategory.Raids, Tier = AchievementTier.Common, XpReward = 200, ConditionType = ConditionType.BossesDefeated, TargetValue = 1, TargetUnit = "boss" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000019"), Title = "Raid Ready", Description = "Defeat 3 bosses.", Icon = "🗡️", Category = AchievementCategory.Raids, Tier = AchievementTier.Uncommon, XpReward = 500, ConditionType = ConditionType.BossesDefeated, TargetValue = 3, TargetUnit = "bosses" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000020"), Title = "Boss Slayer", Description = "Take down 5 bosses.", Icon = "🛡️", Category = AchievementCategory.Raids, Tier = AchievementTier.Rare, XpReward = 1000, ConditionType = ConditionType.BossesDefeated, TargetValue = 5, TargetUnit = "bosses" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000021"), Title = "Raid Champion", Description = "Defeat 10 bosses.", Icon = "👑", Category = AchievementCategory.Raids, Tier = AchievementTier.Epic, XpReward = 2500, ConditionType = ConditionType.BossesDefeated, TargetValue = 10, TargetUnit = "bosses" },
        new() { Id = new Guid("cc000001-0000-0000-0000-000000000022"), Title = "Legendary Raider", Description = "Conquer 25 bosses. You are feared.", Icon = "🏴", Category = AchievementCategory.Raids, Tier = AchievementTier.Legendary, XpReward = 7500, ConditionType = ConditionType.BossesDefeated, TargetValue = 25, TargetUnit = "bosses" },
    ];

    public async Task SeedAsync()
    {
        if (await db.Achievements.AnyAsync()) return;
        db.Achievements.AddRange(Catalog);
        await db.SaveChangesAsync();
    }
}
