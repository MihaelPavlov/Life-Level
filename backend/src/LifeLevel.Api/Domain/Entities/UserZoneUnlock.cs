namespace LifeLevel.Api.Domain.Entities;

public class UserZoneUnlock
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public Guid WorldZoneId { get; set; }
    public WorldZone WorldZone { get; set; } = null!;
    public Guid UserWorldProgressId { get; set; }
    public UserWorldProgress UserWorldProgress { get; set; } = null!;
    public DateTime UnlockedAt { get; set; } = DateTime.UtcNow;
}
