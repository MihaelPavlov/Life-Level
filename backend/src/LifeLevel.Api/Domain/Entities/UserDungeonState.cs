namespace LifeLevel.Api.Domain.Entities;

public class UserDungeonState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public Guid DungeonPortalId { get; set; }
    public DungeonPortal DungeonPortal { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    public UserMapProgress UserMapProgress { get; set; } = null!;
    public bool IsDiscovered { get; set; } = false;
    public int CurrentFloor { get; set; } = 0;
    public DateTime? DiscoveredAt { get; set; }
}
