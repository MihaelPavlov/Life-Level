namespace LifeLevel.Modules.Talents.Domain.Enums;

public enum TalentRarity
{
    Common,
    Rare,
    Epic,
}

/// <summary>
/// What a talent does. The aggregate <c>TalentBonuses</c> has one field per effect type;
/// <c>TalentService</c> sums <c>PerLevelValue * Level</c> for every owned talent into it.
/// </summary>
public enum TalentEffectType
{
    /// <summary>+N effective STR (profile overlay, like gear).</summary>
    StatStrength,
    StatEndurance,
    StatAgility,
    StatFlexibility,
    StatStamina,

    /// <summary>+N% to all activity XP.</summary>
    ActivityXpPct,
    /// <summary>+N% XP for the first activity of the UTC day.</summary>
    MorningXpPct,
    /// <summary>+N% XP for Running / Cycling / Swimming / Hiking / Walking.</summary>
    CardioXpPct,
    /// <summary>+N% XP for Gym / Climbing / Yoga.</summary>
    StrengthStyleXpPct,
    /// <summary>+N% XP for the first activity within 24h of a broken streak.</summary>
    ComebackXpPct,
    /// <summary>+N% to quest reward XP (and the all-5-daily bonus).</summary>
    QuestXpPct,

    /// <summary>+N% boss damage from every workout.</summary>
    BossDamagePct,
    /// <summary>+N% extra boss damage when a boss / raid is active.</summary>
    BossActiveDamagePct,
    /// <summary>+N percentage points added to item drop chance.</summary>
    DropChancePct,

    /// <summary>Auto-recover a 2-day streak gap with no shields, up to floor(value) times/week.</summary>
    SecondWind,
    /// <summary>Grants +1 streak shield each time this talent reaches a new level.</summary>
    ShieldPerLevel,
}

public enum TalentDrawKind
{
    NewTalent,
    Duplicate,
}
