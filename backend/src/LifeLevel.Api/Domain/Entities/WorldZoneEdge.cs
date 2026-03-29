namespace LifeLevel.Api.Domain.Entities;

public class WorldZoneEdge
{
    public Guid Id { get; set; }
    public Guid FromZoneId { get; set; }
    public WorldZone FromZone { get; set; } = null!;
    public Guid ToZoneId { get; set; }
    public WorldZone ToZone { get; set; } = null!;
    public double DistanceKm { get; set; }
    public bool IsBidirectional { get; set; } = true;
}
