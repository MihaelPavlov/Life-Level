using LifeLevel.Modules.Items.Domain.Enums;

namespace LifeLevel.Modules.Items.Application.DTOs;

public class ItemDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public string Rarity { get; set; } = string.Empty;
    public string SlotType { get; set; } = string.Empty;
    public int XpBonusPct { get; set; }
    public int StrBonus { get; set; }
    public int EndBonus { get; set; }
    public int AgiBonus { get; set; }
    public int FlxBonus { get; set; }
    public int StaBonus { get; set; }
}

public class EquipmentSlotDto
{
    public string SlotType { get; set; } = string.Empty;
    public ItemDto? Item { get; set; }
}

public class GearBonusesDto
{
    public int XpBonusPct { get; set; }
    public int StrBonus { get; set; }
    public int EndBonus { get; set; }
    public int AgiBonus { get; set; }
    public int FlxBonus { get; set; }
    public int StaBonus { get; set; }
}

public class CharacterEquipmentResponse
{
    public List<EquipmentSlotDto> Slots { get; set; } = [];
    public GearBonusesDto TotalBonuses { get; set; } = new();
}

public class EquipItemRequest
{
    public Guid CharacterItemId { get; set; }
    public EquipmentSlotType SlotType { get; set; }
}
