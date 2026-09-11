using LifeLevel.Modules.Seasons.Domain.Enums;

namespace LifeLevel.Modules.Seasons.Domain.Entities;

public class SeasonRewardTier
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid SeasonId { get; set; }
    public Season? Season { get; set; }

    /// <summary>1 .. Season.TierCount.</summary>
    public int Tier { get; set; }

    public SeasonTrack Track { get; set; }

    public SeasonRewardType RewardType { get; set; }

    /// <summary>Item id for <see cref="SeasonRewardType.Item"/>; otherwise null.</summary>
    public Guid? RewardRefId { get; set; }

    /// <summary>Title catalog key for <see cref="SeasonRewardType.Title"/>; otherwise null.</summary>
    public string? RewardKey { get; set; }

    /// <summary>XP amount / shield count / flavour Season-XP amount.</summary>
    public int Amount { get; set; }

    public string Label { get; set; } = string.Empty;

    /// <summary>Bare art key the mobile app maps to an asset (e.g. "reward_treasure_chest").</summary>
    public string IconKey { get; set; } = string.Empty;

    /// <summary>Optional rarity tag for tinting ("common"/"uncommon"/"rare"/"epic"/"legendary").</summary>
    public string? Rarity { get; set; }
}
