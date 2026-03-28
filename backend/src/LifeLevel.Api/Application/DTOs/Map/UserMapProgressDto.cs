namespace LifeLevel.Api.Application.DTOs.Map;

public class UserMapProgressDto
{
    public Guid CurrentNodeId { get; set; }
    public Guid? CurrentEdgeId { get; set; }
    public double DistanceTraveledOnEdge { get; set; }
    public Guid? DestinationNodeId { get; set; }
    public List<Guid> UnlockedNodeIds { get; set; } = [];
}
