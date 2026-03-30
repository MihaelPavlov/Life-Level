using LifeLevel.Modules.Items.Domain.Enums;

namespace LifeLevel.Modules.Items.Domain.Entities;

public class EquipmentSlot
{
    public Guid Id { get; set; }
    public Guid CharacterId { get; set; }
    public EquipmentSlotType SlotType { get; set; }
    public Guid? CharacterItemId { get; set; }
    public CharacterItem? CharacterItem { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
