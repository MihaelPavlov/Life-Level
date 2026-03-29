namespace LifeLevel.Modules.Map.Domain.Entities;

public class UserMapProgress
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    // No User nav prop — cross-module FK configured in AppDbContext

    public Guid CurrentNodeId { get; set; }
    public MapNode CurrentNode { get; set; } = null!;

    public Guid? CurrentEdgeId { get; set; }
    public MapEdge? CurrentEdge { get; set; }
    public double DistanceTraveledOnEdge { get; set; } = 0;

    public Guid? DestinationNodeId { get; set; }
    public MapNode? DestinationNode { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<UserNodeUnlock> UnlockedNodes { get; set; } = [];
    // No BossStates/ChestStates/DungeonStates/CrossroadsStates — those are in Adventure modules
}
