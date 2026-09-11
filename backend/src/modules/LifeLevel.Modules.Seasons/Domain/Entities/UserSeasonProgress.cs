namespace LifeLevel.Modules.Seasons.Domain.Entities;

public class UserSeasonProgress
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public Guid SeasonId { get; set; }

    /// <summary>Running total of Season XP earned this season.</summary>
    public long SeasonXp { get; set; }

    /// <summary>Cached derived value: min(TierCount, SeasonXp / XpPerTier).</summary>
    public int CurrentTier { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
