namespace LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;

public class UserDungeonState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    // No User nav prop — cross-module
    public Guid DungeonPortalId { get; set; }
    public DungeonPortal DungeonPortal { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    // No UserMapProgress nav prop — cross-module
    public bool IsDiscovered { get; set; } = false;
    public int CurrentFloor { get; set; } = 0;
    public DateTime? DiscoveredAt { get; set; }
}
