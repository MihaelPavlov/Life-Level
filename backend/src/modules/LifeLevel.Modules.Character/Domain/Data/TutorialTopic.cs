namespace LifeLevel.Modules.Character.Domain.Data;

/// <summary>
/// Tutorial topics — the 5 hub topics users can replay individually.
/// Topic → bit index mapping (MUST match the API contract and mobile client exactly):
///   xp-stats         = bit 0   (value  1)
///   quests-streaks   = bit 1   (value  2)
///   activity-logging = bit 2   (value  4)
///   world-map        = bit 3   (value  8)
///   boss-system      = bit 4   (value 16)
/// </summary>
public static class TutorialTopic
{
    public const string XpStats = "xp-stats";
    public const string QuestsStreaks = "quests-streaks";
    public const string ActivityLogging = "activity-logging";
    public const string WorldMap = "world-map";
    public const string BossSystem = "boss-system";

    /// <summary>
    /// Returns the bitmask value for a given topic key, or null when the key is unknown.
    /// </summary>
    public static int? BitForTopic(string topic) => topic switch
    {
        XpStats         => 1 << 0,
        QuestsStreaks   => 1 << 1,
        ActivityLogging => 1 << 2,
        WorldMap        => 1 << 3,
        BossSystem      => 1 << 4,
        _ => null,
    };

    /// <summary>
    /// Returns the topic bit that should be marked when the tutorial advances FROM the given prior step.
    /// Step 1 & 2 both map to xp-stats (idempotent). Returns 0 when no topic should be marked.
    /// </summary>
    public static int TopicBitForStepAdvance(int priorStep) => priorStep switch
    {
        0 => 1 << 0, // 0 → 1 : xp-stats
        1 => 1 << 0, // 1 → 2 : xp-stats (idempotent)
        2 => 1 << 1, // 2 → 3 : quests-streaks
        3 => 1 << 2, // 3 → 4 : activity-logging
        4 => 1 << 3, // 4 → 5 : world-map
        5 => 1 << 4, // 5 → 6 : boss-system
        _ => 0,
    };
}
