namespace LifeLevel.Api.Domain.Entities;

public class UserMapProgress
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public Guid CurrentNodeId { get; set; }
    public MapNode CurrentNode { get; set; } = null!;

    public Guid? CurrentEdgeId { get; set; }
    public MapEdge? CurrentEdge { get; set; }
    public double DistanceTraveledOnEdge { get; set; } = 0;

    public Guid? DestinationNodeId { get; set; }
    public MapNode? DestinationNode { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<UserNodeUnlock> UnlockedNodes { get; set; } = [];
    public ICollection<UserBossState> BossStates { get; set; } = [];
    public ICollection<UserChestState> ChestStates { get; set; } = [];
    public ICollection<UserDungeonState> DungeonStates { get; set; } = [];
    public ICollection<UserCrossroadsState> CrossroadsStates { get; set; } = [];
}
