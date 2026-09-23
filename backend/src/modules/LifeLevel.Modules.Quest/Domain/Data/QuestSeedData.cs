using LifeLevel.Modules.Quest.Domain.Enums;
using LifeLevel.SharedKernel.Enums;
using QuestEntity = LifeLevel.Modules.Quest.Domain.Entities.Quest;

namespace LifeLevel.Modules.Quest.Domain.Data;

public static class QuestSeedData
{
    // ── Daily Quests ──────────────────────────────────────────────────────────

    public static readonly QuestEntity MorningMover = new()
    {
        Id = Guid.Parse("bbbbbbbb-0001-0000-0000-000000000000"),
        Title = "Morning Mover",
        Description = "Complete any workout lasting at least 30 minutes.",
        Type = QuestType.Daily,
        Category = QuestCategory.Duration,
        RequiredActivity = null,
        TargetValue = 30,
        TargetUnit = "minutes",
        RewardXp = 0,
        SortOrder = 1,
        IsActive = true,
    };

    public static readonly QuestEntity CalorieCrusher = new()
    {
        Id = Guid.Parse("bbbbbbbb-0002-0000-0000-000000000000"),
        Title = "Calorie Crusher",
        Description = "Burn at least 300 calories in a single session.",
        Type = QuestType.Daily,
        Category = QuestCategory.Calories,
        RequiredActivity = null,
        TargetValue = 300,
        TargetUnit = "calories",
        RewardXp = 0,
        SortOrder = 2,
        IsActive = true,
    };

    public static readonly QuestEntity RoadWarrior = new()
    {
        Id = Guid.Parse("bbbbbbbb-0003-0000-0000-000000000000"),
        Title = "Road Warrior",
        Description = "Run at least 5 km.",
        Type = QuestType.Daily,
        Category = QuestCategory.Distance,
        RequiredActivity = ActivityType.Running,
        TargetValue = 5,
        TargetUnit = "km",
        RewardXp = 0,
        SortOrder = 3,
        IsActive = true,
    };

    public static readonly QuestEntity IronSession = new()
    {
        Id = Guid.Parse("bbbbbbbb-0004-0000-0000-000000000000"),
        Title = "Iron Session",
        Description = "Hit the gym for at least 45 minutes.",
        Type = QuestType.Daily,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Gym,
        TargetValue = 45,
        TargetUnit = "minutes",
        RewardXp = 0,
        SortOrder = 4,
        IsActive = true,
    };

    public static readonly QuestEntity ZenMaster = new()
    {
        Id = Guid.Parse("bbbbbbbb-0005-0000-0000-000000000000"),
        Title = "Zen Master",
        Description = "Practice yoga for at least 30 minutes.",
        Type = QuestType.Daily,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Yoga,
        TargetValue = 30,
        TargetUnit = "minutes",
        RewardXp = 0,
        SortOrder = 5,
        IsActive = true,
    };

    public static readonly QuestEntity EndurancePush = new()
    {
        Id = Guid.Parse("bbbbbbbb-0006-0000-0000-000000000000"),
        Title = "Endurance Push",
        Description = "Run for at least 30 minutes.",
        Type = QuestType.Daily,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Running,
        TargetValue = 30,
        TargetUnit = "minutes",
        RewardXp = 0,
        SortOrder = 6,
        IsActive = true,
    };

    public static readonly QuestEntity FirstMove = Task("bbbbbbbb-0101-0000-0000-000000000000", "First Move", "Complete one workout.", QuestType.Daily, QuestCategory.Workouts, null, 1, "workout", 7);
    public static readonly QuestEntity DoubleMove = Task("bbbbbbbb-0102-0000-0000-000000000000", "Double Move", "Complete two workouts.", QuestType.Daily, QuestCategory.Workouts, null, 2, "workouts", 8);
    public static readonly QuestEntity QuickStart = Task("bbbbbbbb-0103-0000-0000-000000000000", "Quick Start", "Stay active for 10 minutes.", QuestType.Daily, QuestCategory.Duration, null, 10, "minutes", 9);
    public static readonly QuestEntity PowerHour = Task("bbbbbbbb-0104-0000-0000-000000000000", "Power Hour", "Stay active for 60 minutes.", QuestType.Daily, QuestCategory.Duration, null, 60, "minutes", 10);
    public static readonly QuestEntity FirstBurn = Task("bbbbbbbb-0105-0000-0000-000000000000", "First Burn", "Burn 100 calories.", QuestType.Daily, QuestCategory.Calories, null, 100, "calories", 11);
    public static readonly QuestEntity FirstKilometer = Task("bbbbbbbb-0106-0000-0000-000000000000", "First Kilometer", "Cover 1 km.", QuestType.Daily, QuestCategory.Distance, null, 1, "km", 12);
    public static readonly QuestEntity DistanceDay = Task("bbbbbbbb-0107-0000-0000-000000000000", "Distance Day", "Cover 3 km.", QuestType.Daily, QuestCategory.Distance, null, 3, "km", 13);
    public static readonly QuestEntity CycleCircuit = Task("bbbbbbbb-0108-0000-0000-000000000000", "Cycle Circuit", "Cycle 5 km.", QuestType.Daily, QuestCategory.Distance, ActivityType.Cycling, 5, "km", 14);
    public static readonly QuestEntity PoolTime = Task("bbbbbbbb-0109-0000-0000-000000000000", "Pool Time", "Swim for 20 minutes.", QuestType.Daily, QuestCategory.Duration, ActivityType.Swimming, 20, "minutes", 15);

    // ── Weekly Quests ─────────────────────────────────────────────────────────

    public static readonly QuestEntity TripleThreat = new()
    {
        Id = Guid.Parse("bbbbbbbb-0007-0000-0000-000000000000"),
        Title = "Triple Threat",
        Description = "Complete 3 workouts this week.",
        Type = QuestType.Weekly,
        Category = QuestCategory.Workouts,
        RequiredActivity = null,
        TargetValue = 3,
        TargetUnit = "workouts",
        RewardXp = 0,
        SortOrder = 1,
        IsActive = true,
    };

    public static readonly QuestEntity RoadRunner = new()
    {
        Id = Guid.Parse("bbbbbbbb-0008-0000-0000-000000000000"),
        Title = "Road Runner",
        Description = "Run a total of 10 km this week.",
        Type = QuestType.Weekly,
        Category = QuestCategory.Distance,
        RequiredActivity = ActivityType.Running,
        TargetValue = 10,
        TargetUnit = "km",
        RewardXp = 0,
        SortOrder = 2,
        IsActive = true,
    };

    public static readonly QuestEntity IronWeek = new()
    {
        Id = Guid.Parse("bbbbbbbb-0009-0000-0000-000000000000"),
        Title = "Iron Week",
        Description = "Spend at least 90 minutes at the gym this week.",
        Type = QuestType.Weekly,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Gym,
        TargetValue = 90,
        TargetUnit = "minutes",
        RewardXp = 0,
        SortOrder = 3,
        IsActive = true,
    };

    public static readonly QuestEntity FiveStrong = Task("bbbbbbbb-0201-0000-0000-000000000000", "Five Strong", "Complete 5 workouts this week.", QuestType.Weekly, QuestCategory.Workouts, null, 5, "workouts", 4);
    public static readonly QuestEntity PerfectWeek = Task("bbbbbbbb-0202-0000-0000-000000000000", "Perfect Week", "Complete 7 workouts this week.", QuestType.Weekly, QuestCategory.Workouts, null, 7, "workouts", 5);
    public static readonly QuestEntity ActiveNinety = Task("bbbbbbbb-0203-0000-0000-000000000000", "Active Ninety", "Log 90 active minutes this week.", QuestType.Weekly, QuestCategory.Duration, null, 90, "minutes", 6);
    public static readonly QuestEntity ThreeHourHero = Task("bbbbbbbb-0204-0000-0000-000000000000", "Three Hour Hero", "Log 180 active minutes this week.", QuestType.Weekly, QuestCategory.Duration, null, 180, "minutes", 7);
    public static readonly QuestEntity FiveHourForce = Task("bbbbbbbb-0205-0000-0000-000000000000", "Five Hour Force", "Log 300 active minutes this week.", QuestType.Weekly, QuestCategory.Duration, null, 300, "minutes", 8);
    public static readonly QuestEntity WeeklyBurn500 = Task("bbbbbbbb-0206-0000-0000-000000000000", "Kindle the Flame", "Burn 500 calories this week.", QuestType.Weekly, QuestCategory.Calories, null, 500, "calories", 9);
    public static readonly QuestEntity WeeklyBurn1000 = Task("bbbbbbbb-0207-0000-0000-000000000000", "Blazing Week", "Burn 1,000 calories this week.", QuestType.Weekly, QuestCategory.Calories, null, 1000, "calories", 10);
    public static readonly QuestEntity WeeklyBurn2000 = Task("bbbbbbbb-0208-0000-0000-000000000000", "Inferno Week", "Burn 2,000 calories this week.", QuestType.Weekly, QuestCategory.Calories, null, 2000, "calories", 11);
    public static readonly QuestEntity WeeklyDistance5 = Task("bbbbbbbb-0209-0000-0000-000000000000", "First Five", "Cover 5 km this week.", QuestType.Weekly, QuestCategory.Distance, null, 5, "km", 12);
    public static readonly QuestEntity WeeklyDistance15 = Task("bbbbbbbb-0210-0000-0000-000000000000", "Distance Fifteen", "Cover 15 km this week.", QuestType.Weekly, QuestCategory.Distance, null, 15, "km", 13);
    public static readonly QuestEntity WeeklyDistance30 = Task("bbbbbbbb-0211-0000-0000-000000000000", "Long Haul", "Cover 30 km this week.", QuestType.Weekly, QuestCategory.Distance, null, 30, "km", 14);
    public static readonly QuestEntity YogaWeek = Task("bbbbbbbb-0212-0000-0000-000000000000", "Yoga Week", "Practice yoga for 60 minutes this week.", QuestType.Weekly, QuestCategory.Duration, ActivityType.Yoga, 60, "minutes", 15);
    public static readonly QuestEntity CycleWeek = Task("bbbbbbbb-0213-0000-0000-000000000000", "Cycle Week", "Cycle 25 km this week.", QuestType.Weekly, QuestCategory.Distance, ActivityType.Cycling, 25, "km", 16);
    public static readonly QuestEntity SwimWeek = Task("bbbbbbbb-0214-0000-0000-000000000000", "Swim Week", "Swim for 60 minutes this week.", QuestType.Weekly, QuestCategory.Duration, ActivityType.Swimming, 60, "minutes", 17);
    public static readonly QuestEntity ClimbWeek = Task("bbbbbbbb-0215-0000-0000-000000000000", "Climb Week", "Climb for 60 minutes this week.", QuestType.Weekly, QuestCategory.Duration, ActivityType.Climbing, 60, "minutes", 18);
    public static readonly QuestEntity HikeWeek = Task("bbbbbbbb-0216-0000-0000-000000000000", "Hike Week", "Hike 10 km this week.", QuestType.Weekly, QuestCategory.Distance, ActivityType.Hiking, 10, "km", 19);
    public static readonly QuestEntity WalkWeek = Task("bbbbbbbb-0217-0000-0000-000000000000", "Walk Week", "Walk 20 km this week.", QuestType.Weekly, QuestCategory.Distance, ActivityType.Walking, 20, "km", 20);

    // ── Special Quests ────────────────────────────────────────────────────────

    public static readonly QuestEntity FirstSteps = new()
    {
        Id = Guid.Parse("bbbbbbbb-0010-0000-0000-000000000000"),
        Title = "First Steps",
        Description = "Run a total of 10 km across all activities.",
        Type = QuestType.Special,
        Category = QuestCategory.Distance,
        RequiredActivity = ActivityType.Running,
        TargetValue = 10,
        TargetUnit = "km",
        RewardXp = 1000,
        SortOrder = 1,
        IsActive = true,
    };

    public static readonly QuestEntity SummitSeeker = new()
    {
        Id = Guid.Parse("bbbbbbbb-0011-0000-0000-000000000000"),
        Title = "Summit Seeker",
        Description = "Spend 60 minutes climbing.",
        Type = QuestType.Special,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Climbing,
        TargetValue = 60,
        TargetUnit = "minutes",
        RewardXp = 1200,
        SortOrder = 2,
        IsActive = true,
    };

    public static readonly QuestEntity EnduranceInitiate = new()
    {
        Id = Guid.Parse("bbbbbbbb-0012-0000-0000-000000000000"),
        Title = "Endurance Initiate",
        Description = "Log a total of 500 minutes of any activity.",
        Type = QuestType.Special,
        Category = QuestCategory.Duration,
        RequiredActivity = null,
        TargetValue = 500,
        TargetUnit = "minutes",
        RewardXp = 2000,
        SortOrder = 3,
        IsActive = true,
    };

    public static readonly QuestEntity[] All =
    [
        MorningMover,
        CalorieCrusher,
        RoadWarrior,
        IronSession,
        ZenMaster,
        EndurancePush,
        FirstMove, DoubleMove, QuickStart, PowerHour, FirstBurn,
        FirstKilometer, DistanceDay, CycleCircuit, PoolTime,
        TripleThreat,
        RoadRunner,
        IronWeek,
        FiveStrong, PerfectWeek, ActiveNinety, ThreeHourHero, FiveHourForce,
        WeeklyBurn500, WeeklyBurn1000, WeeklyBurn2000,
        WeeklyDistance5, WeeklyDistance15, WeeklyDistance30,
        YogaWeek, CycleWeek, SwimWeek, ClimbWeek, HikeWeek, WalkWeek,
        FirstSteps,
        SummitSeeker,
        EnduranceInitiate,
    ];

    private static QuestEntity Task(
        string id, string title, string description, QuestType type,
        QuestCategory category, ActivityType? activity, double target,
        string unit, int sortOrder) => new()
    {
        Id = Guid.Parse(id),
        Title = title,
        Description = description,
        Type = type,
        Category = category,
        RequiredActivity = activity,
        TargetValue = target,
        TargetUnit = unit,
        RewardXp = 0,
        SortOrder = sortOrder,
        IsActive = true,
    };
}
