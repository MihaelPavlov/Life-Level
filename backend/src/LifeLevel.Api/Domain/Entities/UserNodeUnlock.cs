namespace LifeLevel.Api.Domain.Entities;

public class UserNodeUnlock
{
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public Guid MapNodeId { get; set; }
    public MapNode MapNode { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    public UserMapProgress UserMapProgress { get; set; } = null!;
    public DateTime UnlockedAt { get; set; } = DateTime.UtcNow;
}
