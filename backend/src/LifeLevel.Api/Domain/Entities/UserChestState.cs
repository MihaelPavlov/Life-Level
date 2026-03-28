namespace LifeLevel.Api.Domain.Entities;

public class UserChestState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public Guid ChestId { get; set; }
    public Chest Chest { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    public UserMapProgress UserMapProgress { get; set; } = null!;
    public bool IsCollected { get; set; } = false;
    public DateTime? CollectedAt { get; set; }
}
