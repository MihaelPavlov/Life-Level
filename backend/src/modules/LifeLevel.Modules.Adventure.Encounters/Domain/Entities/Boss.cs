namespace LifeLevel.Modules.Adventure.Encounters.Domain.Entities;

public class Boss
{
    public Guid Id { get; set; }

    /// <summary>
    /// Legacy local-map node FK. Null for world-zone bosses (bridged via
    /// <see cref="WorldZoneId"/>).
    /// </summary>
    public Guid? NodeId { get; set; }
    // No MapNode nav prop — cross-module FK configured in AppDbContext
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public int MaxHp { get; set; }
    public int RewardXp { get; set; }
    public int TimerDays { get; set; } = 7;
    public bool IsMini { get; set; } = false;

    /// <summary>
    /// Bridge link to a WorldZone (overworld) boss zone. When set, this legacy
    /// Boss row represents a region-boss lazy-spawned when the user arrives at
    /// the world-zone. Null for legacy local-map bosses. No EF FK — cross-module
    /// coupling is kept loose; treated as a soft reference.
    /// </summary>
    public Guid? WorldZoneId { get; set; }

    /// <summary>
    /// When true, the BossService damage pipeline skips 7-day expiry checks.
    /// World-zone bosses never expire until defeated.
    /// </summary>
    public bool SuppressExpiry { get; set; } = false;

    public ICollection<UserBossState> UserStates { get; set; } = [];
}
