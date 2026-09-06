using LifeLevel.Modules.Seasons.Domain.Entities;
using LifeLevel.Modules.Seasons.Domain.Enums;

namespace LifeLevel.Modules.Seasons.Domain;

/// <summary>
/// The seeded reward table for Season 1 "Trail of Embers" — 25 tiers × 2 lanes.
/// Built only from primitives that can be granted for real today. Admin-editable after seeding.
/// </summary>
public static class SeasonOneCatalog
{
    public const string SeasonName = "Trail of Embers";
    public const string Theme = "ember";
    public const int TierCount = 25;
    public const int MilestoneTier = 25;
    public const int XpPerTier = 600;
    public const int DurationDays = 56;

    // Item catalog ids (see ItemSeeder).
    private static readonly Guid IronHeadband     = new("10000000-0000-0000-0000-000000000007");
    private static readonly Guid CompressionShirt = new("10000000-0000-0000-0000-000000000013");
    private static readonly Guid ZoneCompass      = new("10000000-0000-0000-0000-000000000027");
    private static readonly Guid CarbonX3         = new("10000000-0000-0000-0000-000000000005");
    private static readonly Guid ClimbingChalkBag = new("10000000-0000-0000-0000-000000000018");
    private static readonly Guid SpeedSpikes      = new("10000000-0000-0000-0000-000000000015");
    private static readonly Guid GripWraps        = new("10000000-0000-0000-0000-000000000004");
    private static readonly Guid SportBuds        = new("10000000-0000-0000-0000-000000000006");
    private static readonly Guid CryoJersey       = new("10000000-0000-0000-0000-000000000003");
    private static readonly Guid TrailRunnerX5    = new("10000000-0000-0000-0000-000000000008");
    private static readonly Guid AuraStone        = new("10000000-0000-0000-0000-000000000021");
    private static readonly Guid ChampionGloves   = new("10000000-0000-0000-0000-000000000020");

    public static List<SeasonRewardTier> Build(Guid seasonId)
    {
        var rows = new List<SeasonRewardTier>();
        void Free(int tier, SeasonRewardType type, int amount, string label, string icon,
                  Guid? refId = null, string? key = null, string? rarity = null) =>
            rows.Add(Row(seasonId, tier, SeasonTrack.Free, type, amount, label, icon, refId, key, rarity));
        void Founder(int tier, SeasonRewardType type, int amount, string label, string icon,
                     Guid? refId = null, string? key = null, string? rarity = null) =>
            rows.Add(Row(seasonId, tier, SeasonTrack.Founder, type, amount, label, icon, refId, key, rarity));

        // ── Free lane ───────────────────────────────────────────────────────────
        Free(1,  SeasonRewardType.SeasonXp,     150, "+150 Season XP",   "reward_xp_sparkle");
        Free(2,  SeasonRewardType.Xp,           250, "+250 XP",          "reward_xp_sparkle");
        Free(3,  SeasonRewardType.StreakShield, 1,   "Streak Freeze ×1", "reward_streak_shield");
        Free(4,  SeasonRewardType.SeasonXp,     200, "+200 Season XP",   "reward_xp_sparkle");
        Free(5,  SeasonRewardType.Xp,           300, "+300 XP",          "reward_xp_sparkle");
        Free(6,  SeasonRewardType.SeasonXp,     300, "+300 Season XP",   "reward_xp_sparkle");
        Free(7,  SeasonRewardType.Item,         0,   "Ember Cache",      "reward_treasure_chest", refId: ZoneCompass, rarity: "uncommon");
        Free(8,  SeasonRewardType.Xp,           400, "+400 XP",          "reward_xp_sparkle");
        Free(9,  SeasonRewardType.StreakShield, 1,   "Streak Freeze ×1", "reward_streak_shield");
        Free(10, SeasonRewardType.SeasonXp,     400, "+400 Season XP",   "reward_xp_sparkle");
        Free(11, SeasonRewardType.Xp,           400, "+400 XP",          "reward_xp_sparkle");
        Free(12, SeasonRewardType.SeasonXp,     350, "+350 Season XP",   "reward_xp_sparkle");
        Free(13, SeasonRewardType.StreakShield, 1,   "Streak Freeze ×1", "reward_streak_shield");
        Free(14, SeasonRewardType.Xp,           500, "+500 XP",          "reward_xp_sparkle");
        Free(15, SeasonRewardType.Title,        0,   "\"Streak Master\" title", "title_marathoner", key: "streak-master", rarity: "rare");
        Free(16, SeasonRewardType.SeasonXp,     400, "+400 Season XP",   "reward_xp_sparkle");
        Free(17, SeasonRewardType.Xp,           500, "+500 XP",          "reward_xp_sparkle");
        Free(18, SeasonRewardType.StreakShield, 1,   "Streak Freeze ×1", "reward_streak_shield");
        Free(19, SeasonRewardType.SeasonXp,     450, "+450 Season XP",   "reward_xp_sparkle");
        Free(20, SeasonRewardType.Item,         0,   "Sport Buds",       "reward_treasure_chest", refId: SportBuds, rarity: "rare");
        Free(21, SeasonRewardType.Xp,           600, "+600 XP",          "reward_xp_sparkle");
        Free(22, SeasonRewardType.SeasonXp,     500, "+500 Season XP",   "reward_xp_sparkle");
        Free(23, SeasonRewardType.StreakShield, 1,   "Streak Freeze ×1", "reward_streak_shield");
        Free(24, SeasonRewardType.Xp,           800, "+800 XP",          "reward_xp_sparkle");
        Free(25, SeasonRewardType.Xp,           1500, "Trailblazer bonus", "reward_xp_storm");

        // ── Founder lane ────────────────────────────────────────────────────────
        Founder(1,  SeasonRewardType.Xp,           250, "+250 XP",           "reward_xp_sparkle");
        Founder(2,  SeasonRewardType.StreakShield, 1,   "Streak Freeze ×1",  "reward_streak_shield");
        Founder(3,  SeasonRewardType.Xp,           400, "+400 XP",           "reward_xp_sparkle");
        Founder(4,  SeasonRewardType.Item,         0,   "Iron Headband",     "reward_treasure_chest", refId: IronHeadband, rarity: "common");
        Founder(5,  SeasonRewardType.Title,        0,   "\"The Marathoner\" title", "title_marathoner", key: "the-marathoner", rarity: "rare");
        Founder(6,  SeasonRewardType.Item,         0,   "Compression Shirt", "reward_treasure_chest", refId: CompressionShirt, rarity: "uncommon");
        Founder(7,  SeasonRewardType.Xp,           600, "+600 XP",           "reward_xp_sparkle");
        Founder(8,  SeasonRewardType.Item,         0,   "Carbon X3",         "reward_treasure_chest", refId: CarbonX3, rarity: "uncommon");
        Founder(9,  SeasonRewardType.Xp,           500, "+500 XP",           "reward_xp_sparkle");
        Founder(10, SeasonRewardType.Item,         0,   "Aura Stone",        "item_aura_stone", refId: AuraStone, rarity: "epic");
        Founder(11, SeasonRewardType.Xp,           500, "+500 XP",           "reward_xp_sparkle");
        Founder(12, SeasonRewardType.Item,         0,   "Climbing Chalk Bag","reward_treasure_chest", refId: ClimbingChalkBag, rarity: "uncommon");
        Founder(13, SeasonRewardType.Xp,           600, "+600 XP",           "reward_xp_sparkle");
        Founder(14, SeasonRewardType.Item,         0,   "Cryo Jersey",       "reward_treasure_chest", refId: CryoJersey, rarity: "rare");
        Founder(15, SeasonRewardType.Title,        0,   "\"Raid Veteran\" title", "rank_veteran", key: "raid-veteran", rarity: "rare");
        Founder(16, SeasonRewardType.Item,         0,   "Grip Wraps",        "reward_treasure_chest", refId: GripWraps, rarity: "rare");
        Founder(17, SeasonRewardType.Xp,           700, "+700 XP",           "reward_xp_sparkle");
        Founder(18, SeasonRewardType.Item,         0,   "Speed Spikes",      "reward_treasure_chest", refId: SpeedSpikes, rarity: "rare");
        Founder(19, SeasonRewardType.Xp,           800, "+800 XP",           "reward_xp_sparkle");
        Founder(20, SeasonRewardType.Item,         0,   "Trail Runner X5",   "reward_treasure_chest", refId: TrailRunnerX5, rarity: "epic");
        Founder(21, SeasonRewardType.Xp,           900, "+900 XP",           "reward_xp_sparkle");
        Founder(22, SeasonRewardType.Cosmetic,     0,   "Ember Trail (preview)", "reward_xp_storm", rarity: "epic");
        Founder(23, SeasonRewardType.Xp,           1000, "+1000 XP",         "reward_xp_sparkle");
        Founder(24, SeasonRewardType.Item,         0,   "Champion Gloves",   "item_champion_gloves", refId: ChampionGloves, rarity: "legendary");
        Founder(25, SeasonRewardType.Title,        0,   "Ember Aura + \"The Champion\"", "title_champion", key: "the-champion", rarity: "legendary");

        return rows;
    }

    private static SeasonRewardTier Row(
        Guid seasonId, int tier, SeasonTrack track, SeasonRewardType type, int amount,
        string label, string icon, Guid? refId, string? key, string? rarity) => new()
    {
        Id = Guid.NewGuid(),
        SeasonId = seasonId,
        Tier = tier,
        Track = track,
        RewardType = type,
        Amount = amount,
        Label = label,
        IconKey = icon,
        RewardRefId = refId,
        RewardKey = key,
        Rarity = rarity,
    };
}
