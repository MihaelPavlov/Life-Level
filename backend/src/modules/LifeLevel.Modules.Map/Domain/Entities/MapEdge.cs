namespace LifeLevel.Modules.Map.Domain.Entities;

public class MapEdge
{
    public Guid Id { get; set; }
    public Guid FromNodeId { get; set; }
    public MapNode FromNode { get; set; } = null!;
    public Guid ToNodeId { get; set; }
    public MapNode ToNode { get; set; } = null!;
    public double DistanceKm { get; set; }
    public bool IsBidirectional { get; set; } = true;
}
