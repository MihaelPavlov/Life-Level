namespace LifeLevel.Modules.Items.Domain.Entities;

public class CharacterItem
{
    public Guid Id { get; set; }
    public Guid CharacterId { get; set; }
    public Guid ItemId { get; set; }
    public Item Item { get; set; } = null!;
    public bool IsEquipped { get; set; }
    public DateTime AcquiredAt { get; set; } = DateTime.UtcNow;
}
