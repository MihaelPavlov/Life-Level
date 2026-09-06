namespace LifeLevel.Modules.Seasons.Domain.Enums;

public enum SeasonState
{
    Scheduled,
    Active,
    Ended,
}

public enum SeasonTrack
{
    Free,
    Founder,
}

public enum SeasonRewardType
{
    /// <summary>Flavour "Season XP" currency — adds to the user's SeasonXp total.</summary>
    SeasonXp,
    /// <summary>Real character XP via ICharacterXpPort.</summary>
    Xp,
    /// <summary>A catalog item via IItemRewardGrantPort. RewardRefId = item id.</summary>
    Item,
    /// <summary>Streak freeze / shield via IStreakShieldPort. Amount = count.</summary>
    StreakShield,
    /// <summary>A title via ITitleUnlockPort. RewardKey = title catalog key.</summary>
    Title,
    /// <summary>Cosmetic (frame / aura / mount) — recorded only, no backing system yet.</summary>
    Cosmetic,
}

public enum FounderPassSource
{
    Purchase,
    AdminGrant,
    Auto,
}
