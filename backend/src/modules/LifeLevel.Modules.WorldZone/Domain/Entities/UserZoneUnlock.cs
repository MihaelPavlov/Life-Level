namespace LifeLevel.Modules.WorldZone.Domain.Entities;

public class UserZoneUnlock
{
    public Guid UserId { get; set; }
    // No User navigation property — cross-module FK configured in AppDbContext
    public Guid WorldZoneId { get; set; }
    public WorldZone WorldZone { get; set; } = null!;
    public Guid UserWorldProgressId { get; set; }
    public UserWorldProgress UserWorldProgress { get; set; } = null!;
    public DateTime UnlockedAt { get; set; } = DateTime.UtcNow;
}
