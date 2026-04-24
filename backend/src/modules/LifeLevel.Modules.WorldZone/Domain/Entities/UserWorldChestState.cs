namespace LifeLevel.Modules.WorldZone.Domain.Entities;

/// <summary>
/// One-shot chest opening state. Unique per (UserId, WorldZoneId). The presence
/// of a row indicates the user has permanently opened this chest zone and
/// cannot open it again.
/// </summary>
public class UserWorldChestState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid WorldZoneId { get; set; }
    public DateTime OpenedAt { get; set; } = DateTime.UtcNow;
}
