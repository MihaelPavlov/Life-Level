using LifeLevel.Modules.Items.Domain.Enums;

namespace LifeLevel.Modules.Items.Domain.Entities;

public class Item
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty; // emoji
    public ItemRarity Rarity { get; set; }
    public ItemCategory Category { get; set; }
    public EquipmentSlotType SlotType { get; set; }
    public int XpBonusPct { get; set; }
    public int StrBonus { get; set; }
    public int EndBonus { get; set; }
    public int AgiBonus { get; set; }
    public int FlxBonus { get; set; }
    public int StaBonus { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
