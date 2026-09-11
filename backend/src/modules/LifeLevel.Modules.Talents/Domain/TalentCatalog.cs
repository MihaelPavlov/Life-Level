using LifeLevel.Modules.Talents.Domain.Entities;
using LifeLevel.Modules.Talents.Domain.Enums;

namespace LifeLevel.Modules.Talents.Domain;

/// <summary>
/// The v1 talent catalog (16 talents). Seeded by <c>TalentSeeder</c> on first run; every field
/// is admin-editable afterwards. Pattern: <c>SeasonOneCatalog</c>.
/// </summary>
public static class TalentCatalog
{
    public static IReadOnlyList<Talent> Build() => Defs
        .Select((d, i) => new Talent
        {
            Id = Guid.NewGuid(),
            Key = d.Key,
            Name = d.Name,
            Description = d.Description,
            IconKey = d.IconKey,
            Rarity = d.Rarity,
            EffectType = d.EffectType,
            PerLevelValue = d.PerLevelValue,
            MaxLevel = 10,
            DrawWeight = d.DrawWeight,
            SortOrder = i,
            IsActive = true,
        })
        .ToList();

    private record Def(
        string Key, string Name, string Description, string IconKey,
        TalentRarity Rarity, TalentEffectType EffectType, double PerLevelValue, int DrawWeight);

    private static readonly Def[] Defs =
    [
        // ── Stat (Common) ──────────────────────────────────────────────────
        new("iron-grip", "Iron Grip", "+1 effective Strength per level.",
            "stat_strength", TalentRarity.Common, TalentEffectType.StatStrength, 1, 120),
        new("deep-lungs", "Deep Lungs", "+1 effective Endurance per level.",
            "stat_endurance", TalentRarity.Common, TalentEffectType.StatEndurance, 1, 120),
        new("fast-twitch", "Fast Twitch", "+1 effective Agility per level.",
            "stat_agility", TalentRarity.Common, TalentEffectType.StatAgility, 1, 120),
        new("loose-joints", "Loose Joints", "+1 effective Flexibility per level.",
            "stat_flexibility", TalentRarity.Common, TalentEffectType.StatFlexibility, 1, 120),
        new("second-engine", "Second Engine", "+1 effective Stamina per level.",
            "stat_stamina", TalentRarity.Common, TalentEffectType.StatStamina, 1, 120),

        // ── XP (Common / Rare) ─────────────────────────────────────────────
        new("focused-training", "Focused Training", "+1% XP from every workout, per level.",
            "reward_xp_sparkle", TalentRarity.Common, TalentEffectType.ActivityXpPct, 1, 110),
        new("morning-momentum", "Morning Momentum", "First workout each day: +2.5% XP per level.",
            "reward_streak_fire", TalentRarity.Rare, TalentEffectType.MorningXpPct, 2.5, 70),
        new("runners-high", "Runner's High", "Running / cycling / swimming / hiking: +1% XP per level.",
            "activity_running", TalentRarity.Common, TalentEffectType.CardioXpPct, 1, 100),
        new("iron-discipline", "Iron Discipline", "Gym / climbing / yoga: +1% XP per level.",
            "activity_gym", TalentRarity.Common, TalentEffectType.StrengthStyleXpPct, 1, 100),
        new("quest-zeal", "Quest Zeal", "+2% quest reward XP per level.",
            "quest_general", TalentRarity.Rare, TalentEffectType.QuestXpPct, 2, 70),

        // ── Streak (Rare / Epic) ───────────────────────────────────────────
        new("second-wind", "Second Wind", "Auto-save a missed day with no shield, up to level/2 times per week.",
            "reward_streak_shield", TalentRarity.Epic, TalentEffectType.SecondWind, 1, 40),
        new("steel-resolve", "Steel Resolve", "First workout within 24h of a broken streak: +5% XP per level.",
            "reward_streak_fire", TalentRarity.Rare, TalentEffectType.ComebackXpPct, 5, 60),
        new("shield-craft", "Shield Craft", "Earn +1 streak shield each time this talent levels up.",
            "reward_streak_shield", TalentRarity.Rare, TalentEffectType.ShieldPerLevel, 1, 60),

        // ── Boss / reward (Rare / Epic) ────────────────────────────────────
        new("direct-hit", "Direct Hit", "+2% boss damage from every workout, per level.",
            "ring_boss", TalentRarity.Rare, TalentEffectType.BossDamagePct, 2, 70),
        new("boss-instinct", "Boss Instinct", "While a boss or raid is active: extra +2% boss damage per level.",
            "ring_boss", TalentRarity.Epic, TalentEffectType.BossActiveDamagePct, 2, 40),
        new("fair-exchange", "Fair Exchange", "+1 percentage point to item drop chance per level.",
            "reward_treasure_chest", TalentRarity.Rare, TalentEffectType.DropChancePct, 1, 60),
    ];
}
