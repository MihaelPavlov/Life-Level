namespace LifeLevel.Api.Application.DTOs.Map;

public class MapEdgeDto
{
    public Guid Id { get; set; }
    public Guid FromNodeId { get; set; }
    public Guid ToNodeId { get; set; }
    public double DistanceKm { get; set; }
    public bool IsBidirectional { get; set; }
}
