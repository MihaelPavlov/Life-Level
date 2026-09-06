using LifeLevel.Modules.Seasons.Domain.Enums;

namespace LifeLevel.Modules.Seasons.Domain.Entities;

public class Season
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>1, 2, 3 … — display / ordering.</summary>
    public int Number { get; set; }

    public string Name { get; set; } = string.Empty;

    /// <summary>Short slug (e.g. "ember", "tide") — drives the mobile accent colour.</summary>
    public string Theme { get; set; } = "ember";

    public DateTime StartsAt { get; set; }
    public DateTime EndsAt { get; set; }

    public SeasonState State { get; set; } = SeasonState.Scheduled;

    /// <summary>Season XP needed to advance one tier.</summary>
    public int XpPerTier { get; set; } = 600;

    public int TierCount { get; set; } = 25;

    public int MilestoneTier { get; set; } = 25;

    public ICollection<SeasonRewardTier> Tiers { get; set; } = new List<SeasonRewardTier>();
}
