namespace LifeLevel.Modules.Character.Domain.Data;

public static class TitleCatalog
{
    public static readonly (Guid Id, string Emoji, string Name, string UnlockCondition, string UnlockCriteria, int SortOrder)[] Titles =
    [
        (
            Guid.Parse("A0000000-0000-0000-0000-000000000001"),
            "🏃", "The Marathoner",
            "Complete 5 quests",
            "QuestsCompleted:5",
            1
        ),
        (
            Guid.Parse("A0000000-0000-0000-0000-000000000002"),
            "🔥", "Streak Master",
            "Maintain a 30-day streak",
            "StreakDays:30",
            2
        ),
        (
            Guid.Parse("A0000000-0000-0000-0000-000000000003"),
            "💀", "Raid Veteran",
            "Defeat 3 bosses",
            "BossesDefeated:3",
            3
        ),
        (
            Guid.Parse("A0000000-0000-0000-0000-000000000004"),
            "🌅", "5AM Club",
            "Defeat 10 bosses",
            "BossesDefeated:10",
            4
        ),
        (
            Guid.Parse("A0000000-0000-0000-0000-000000000005"),
            "👑", "The Champion",
            "Reach Champion rank",
            "Rank:Champion",
            5
        ),
        (
            Guid.Parse("A0000000-0000-0000-0000-000000000006"),
            "🌟", "The Unstoppable",
            "Reach Legend rank",
            "Rank:Legend",
            6
        ),
    ];
}
