using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Domain.Data;

public static class QuestSeedData
{
    // ── Daily Quests ──────────────────────────────────────────────────────────

    public static readonly Quest MorningMover = new()
    {
        Id = Guid.Parse("bbbbbbbb-0001-0000-0000-000000000000"),
        Title = "Morning Mover",
        Description = "Complete any workout lasting at least 30 minutes.",
        Type = QuestType.Daily,
        Category = QuestCategory.Duration,
        RequiredActivity = null,
        TargetValue = 30,
        TargetUnit = "minutes",
        RewardXp = 150,
        SortOrder = 1,
        IsActive = true,
    };

    public static readonly Quest CalorieCrusher = new()
    {
        Id = Guid.Parse("bbbbbbbb-0002-0000-0000-000000000000"),
        Title = "Calorie Crusher",
        Description = "Burn at least 300 calories in a single session.",
        Type = QuestType.Daily,
        Category = QuestCategory.Calories,
        RequiredActivity = null,
        TargetValue = 300,
        TargetUnit = "calories",
        RewardXp = 200,
        SortOrder = 2,
        IsActive = true,
    };

    public static readonly Quest RoadWarrior = new()
    {
        Id = Guid.Parse("bbbbbbbb-0003-0000-0000-000000000000"),
        Title = "Road Warrior",
        Description = "Run at least 5 km.",
        Type = QuestType.Daily,
        Category = QuestCategory.Distance,
        RequiredActivity = ActivityType.Running,
        TargetValue = 5,
        TargetUnit = "km",
        RewardXp = 250,
        SortOrder = 3,
        IsActive = true,
    };

    public static readonly Quest IronSession = new()
    {
        Id = Guid.Parse("bbbbbbbb-0004-0000-0000-000000000000"),
        Title = "Iron Session",
        Description = "Hit the gym for at least 45 minutes.",
        Type = QuestType.Daily,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Gym,
        TargetValue = 45,
        TargetUnit = "minutes",
        RewardXp = 200,
        SortOrder = 4,
        IsActive = true,
    };

    public static readonly Quest ZenMaster = new()
    {
        Id = Guid.Parse("bbbbbbbb-0005-0000-0000-000000000000"),
        Title = "Zen Master",
        Description = "Practice yoga for at least 30 minutes.",
        Type = QuestType.Daily,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Yoga,
        TargetValue = 30,
        TargetUnit = "minutes",
        RewardXp = 150,
        SortOrder = 5,
        IsActive = true,
    };

    public static readonly Quest EndurancePush = new()
    {
        Id = Guid.Parse("bbbbbbbb-0006-0000-0000-000000000000"),
        Title = "Endurance Push",
        Description = "Run for at least 30 minutes.",
        Type = QuestType.Daily,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Running,
        TargetValue = 30,
        TargetUnit = "minutes",
        RewardXp = 175,
        SortOrder = 6,
        IsActive = true,
    };

    // ── Weekly Quests ─────────────────────────────────────────────────────────

    public static readonly Quest TripleThreat = new()
    {
        Id = Guid.Parse("bbbbbbbb-0007-0000-0000-000000000000"),
        Title = "Triple Threat",
        Description = "Complete 3 workouts this week.",
        Type = QuestType.Weekly,
        Category = QuestCategory.Workouts,
        RequiredActivity = null,
        TargetValue = 3,
        TargetUnit = "workouts",
        RewardXp = 500,
        SortOrder = 1,
        IsActive = true,
    };

    public static readonly Quest RoadRunner = new()
    {
        Id = Guid.Parse("bbbbbbbb-0008-0000-0000-000000000000"),
        Title = "Road Runner",
        Description = "Run a total of 10 km this week.",
        Type = QuestType.Weekly,
        Category = QuestCategory.Distance,
        RequiredActivity = ActivityType.Running,
        TargetValue = 10,
        TargetUnit = "km",
        RewardXp = 600,
        SortOrder = 2,
        IsActive = true,
    };

    public static readonly Quest IronWeek = new()
    {
        Id = Guid.Parse("bbbbbbbb-0009-0000-0000-000000000000"),
        Title = "Iron Week",
        Description = "Spend at least 90 minutes at the gym this week.",
        Type = QuestType.Weekly,
        Category = QuestCategory.Duration,
        RequiredActivity = ActivityType.Gym,
        TargetValue = 90,
        TargetUnit = "minutes",
        RewardXp = 550,
        SortOrder = 3,
        IsActive = true,
    };

    // ── Special Quests ────────────────────────────────────────────────────────

    public static readonly Quest FirstSteps = new()
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

    public static readonly Quest SummitSeeker = new()
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

    public static readonly Quest EnduranceInitiate = new()
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

    public static readonly Quest[] All =
    [
        MorningMover,
        CalorieCrusher,
        RoadWarrior,
        IronSession,
        ZenMaster,
        EndurancePush,
        TripleThreat,
        RoadRunner,
        IronWeek,
        FirstSteps,
        SummitSeeker,
        EnduranceInitiate,
    ];
}
