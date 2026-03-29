namespace LifeLevel.Modules.Adventure.Encounters.Domain.Entities;

public class UserChestState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    // No User nav prop — cross-module
    public Guid ChestId { get; set; }
    public Chest Chest { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    // No UserMapProgress nav prop — cross-module
    public bool IsCollected { get; set; } = false;
    public DateTime? CollectedAt { get; set; }
}
