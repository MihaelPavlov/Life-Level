namespace LifeLevel.Api.Domain.Entities;

public class UserWorldProgress
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public Guid CurrentZoneId { get; set; }
    public WorldZone CurrentZone { get; set; } = null!;

    public Guid? CurrentEdgeId { get; set; }
    public WorldZoneEdge? CurrentEdge { get; set; }
    public double DistanceTraveledOnEdge { get; set; } = 0;

    public Guid? DestinationZoneId { get; set; }
    public WorldZone? DestinationZone { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Guid WorldId { get; set; }
    public World World { get; set; } = null!;

    public ICollection<UserZoneUnlock> UnlockedZones { get; set; } = [];
}
