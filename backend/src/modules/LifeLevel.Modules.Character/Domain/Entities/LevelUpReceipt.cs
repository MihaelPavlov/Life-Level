namespace LifeLevel.Modules.Character.Domain.Entities;

public class LevelUpReceipt
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Source { get; set; } = string.Empty;
    public int PreviousLevel { get; set; }
    public int NewLevel { get; set; }
    public int BaseStatPointsGranted { get; set; }
    public int BonusStatPointsGranted { get; set; }
    public int PowerGained { get; set; }
    public int CoinsGranted { get; set; }
    public int PreviousInventorySlots { get; set; }
    public int NewInventorySlots { get; set; }
    public string GrantedItemsJson { get; set; } = "[]";
    public string BlockedItemsJson { get; set; } = "[]";
    public string GrantedTitlesJson { get; set; } = "[]";
    public string AvailableAvatarsJson { get; set; } = "[]";
    public string AvailableRegionsJson { get; set; } = "[]";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? FinalizedAt { get; set; }
    public DateTime? AcknowledgedAt { get; set; }
}
