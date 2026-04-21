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
        (
            // Tutorial completion reward (LL-035). UnlockCriteria "Tutorial:Complete" is
            // intentionally not matched by TitleService.EvaluateCriteria — this title is
            // granted exclusively via ITitleUnlockPort on step 7 completion.
            Guid.Parse("A0000000-0000-0000-0000-000000000007"),
            "🌱", "Novice Adventurer",
            "Complete the tutorial",
            "Tutorial:Complete",
            7
        ),
    ];

    /// <summary>
    /// Stable string keys used by <see cref="LifeLevel.SharedKernel.Ports.ITitleUnlockPort"/>
    /// to grant specific titles without exposing GUIDs to callers. Only titles that are
    /// awarded via explicit unlock (rather than criteria evaluation) need an entry here.
    /// </summary>
    public static readonly IReadOnlyDictionary<string, Guid> KeyToId = new Dictionary<string, Guid>
    {
        ["novice-adventurer"] = Guid.Parse("A0000000-0000-0000-0000-000000000007"),
    };
}
