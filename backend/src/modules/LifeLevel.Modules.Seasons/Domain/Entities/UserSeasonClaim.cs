using LifeLevel.Modules.Seasons.Domain.Enums;

namespace LifeLevel.Modules.Seasons.Domain.Entities;

/// <summary>
/// One row per collected tile. Its existence is the idempotency guard for claiming.
/// </summary>
public class UserSeasonClaim
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public Guid SeasonId { get; set; }

    public int Tier { get; set; }
    public SeasonTrack Track { get; set; }

    public DateTime ClaimedAt { get; set; } = DateTime.UtcNow;

    /// <summary>True when granted by the season-end rollover rather than a manual tap.</summary>
    public bool WasAutoGranted { get; set; }
}
