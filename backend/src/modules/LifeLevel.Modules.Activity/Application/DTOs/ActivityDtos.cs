using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using ActiveEncounterPortDto = LifeLevel.SharedKernel.DTOs.ActiveEncounterPortDto;

namespace LifeLevel.Modules.Activity.Application.DTOs;

public class LogActivityRequest
{
    public ActivityType Type { get; set; }
    public int DurationMinutes { get; set; }
    public double? DistanceKm { get; set; }
    public int? Calories { get; set; }
    public int? HeartRateAvg { get; set; }
}

public record BlockedItemInfo(Guid ItemId, string ItemName, string ItemIcon);

public class LogActivityResult
{
    public Guid ActivityId { get; set; }
    public int XpGained { get; set; }
    public int StrGained { get; set; }
    public int EndGained { get; set; }
    public int AgiGained { get; set; }
    public int FlxGained { get; set; }
    public int StaGained { get; set; }
    public bool LeveledUp { get; set; }
    public int? NewLevel { get; set; }
    public IReadOnlyList<CompletedQuestInfo> CompletedQuests { get; set; } = [];
    public bool StreakUpdated { get; set; }
    public int CurrentStreak { get; set; }
    public bool AllDailyQuestsCompleted { get; set; }
    public int BonusXpAwarded { get; set; }
    public int XpBonusApplied { get; init; } = 0;
    public IReadOnlyList<BlockedItemInfo> BlockedItems { get; init; } = [];
    public LevelUpUnlocksDto? LevelUpUnlocks { get; init; }

    /// <summary>
    /// Populated when this activity cleared a floor of the user's active
    /// dungeon run. Null in the common case (no active run, wrong activity
    /// type, or progress accumulated without clearing).
    /// </summary>
    public FloorCreditResult? FloorCreditResult { get; init; }

    /// <summary>
    /// Bosses (if any) that this activity's auto-damage tick just killed.
    /// Empty list in the common case. The mobile client uses this to surface
    /// a "you defeated &lt;boss&gt;" celebratory popup right after logging.
    /// </summary>
    public IReadOnlyList<BossDefeatedInfo> BossDefeats { get; init; } = [];
    public BossCombatTurnInfo? BossCombatTurn { get; init; }

    /// <summary>
    /// Guild raids defeated by this activity's guild damage tick.
    /// </summary>
    public IReadOnlyList<GuildRaidDefeatedInfo> GuildRaidDefeats { get; init; } = [];

    /// <summary>
    /// Non-null when the workout's distance processing was stopped mid-path by
    /// an NPC encounter. Remaining km are banked on the server. The mobile
    /// client shows the encounter modal instead of navigating away.
    /// </summary>
    public ActiveEncounterPortDto? ActiveEncounter { get; init; }
}

public class ActivityHistoryDto
{
    public Guid Id { get; set; }
    public string Type { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public double DistanceKm { get; set; }
    public int Calories { get; set; }
    public int? HeartRateAvg { get; set; }
    public long XpGained { get; set; }
    public int StrGained { get; set; }
    public int EndGained { get; set; }
    public int AgiGained { get; set; }
    public int FlxGained { get; set; }
    public int StaGained { get; set; }
    public int Steps { get; set; }
    public DateTime LoggedAt { get; set; }
}
