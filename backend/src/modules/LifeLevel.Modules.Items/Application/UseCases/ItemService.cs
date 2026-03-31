using LifeLevel.Modules.Items.Application.DTOs;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Modules.Items.Application.UseCases;

public class ItemService(DbContext db, ICharacterIdReadPort characterIdRead)
{
    private static readonly EquipmentSlotType[] AllSlots =
        Enum.GetValues<EquipmentSlotType>();

    public async Task<CharacterEquipmentResponse> GetCharacterEquipmentAsync(Guid userId)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId);
        if (characterId == null)
            return new CharacterEquipmentResponse();

        var slots = await db.Set<EquipmentSlot>()
            .Where(s => s.CharacterId == characterId)
            .Include(s => s.CharacterItem)
            .ThenInclude(ci => ci!.Item)
            .ToListAsync();

        var slotDtos = AllSlots.Select(slotType =>
        {
            var slot = slots.FirstOrDefault(s => s.SlotType == slotType);
            var item = slot?.CharacterItem?.Item;
            return new EquipmentSlotDto
            {
                SlotType = slotType.ToString(),
                Item = item == null ? null : MapItemDto(item)
            };
        }).ToList();

        var totals = new GearBonusesDto
        {
            XpBonusPct = slotDtos.Where(s => s.Item != null).Sum(s => s.Item!.XpBonusPct),
            StrBonus = slotDtos.Where(s => s.Item != null).Sum(s => s.Item!.StrBonus),
            EndBonus = slotDtos.Where(s => s.Item != null).Sum(s => s.Item!.EndBonus),
            AgiBonus = slotDtos.Where(s => s.Item != null).Sum(s => s.Item!.AgiBonus),
            FlxBonus = slotDtos.Where(s => s.Item != null).Sum(s => s.Item!.FlxBonus),
            StaBonus = slotDtos.Where(s => s.Item != null).Sum(s => s.Item!.StaBonus),
        };

        return new CharacterEquipmentResponse { Slots = slotDtos, TotalBonuses = totals };
    }

    public async Task<CharacterEquipmentResponse> EquipItemAsync(Guid userId, EquipItemRequest req)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId)
            ?? throw new InvalidOperationException("Character not found.");

        var charItem = await db.Set<CharacterItem>()
            .Include(ci => ci.Item)
            .FirstOrDefaultAsync(ci => ci.Id == req.CharacterItemId && ci.CharacterId == characterId)
            ?? throw new InvalidOperationException("Item not found in character's inventory.");

        if (charItem.Item.SlotType != req.SlotType)
            throw new InvalidOperationException($"Item does not fit slot {req.SlotType}.");

        // Unequip anything currently in this slot
        var existing = await db.Set<EquipmentSlot>()
            .FirstOrDefaultAsync(s => s.CharacterId == characterId && s.SlotType == req.SlotType);

        if (existing != null)
        {
            if (existing.CharacterItemId.HasValue)
            {
                var prev = await db.Set<CharacterItem>().FindAsync(existing.CharacterItemId);
                if (prev != null) prev.IsEquipped = false;
            }
            existing.CharacterItemId = charItem.Id;
            existing.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            db.Set<EquipmentSlot>().Add(new EquipmentSlot
            {
                Id = Guid.NewGuid(),
                CharacterId = characterId,
                SlotType = req.SlotType,
                CharacterItemId = charItem.Id,
                UpdatedAt = DateTime.UtcNow
            });
        }

        charItem.IsEquipped = true;
        await db.SaveChangesAsync();

        return await GetCharacterEquipmentAsync(userId);
    }

    public async Task<CharacterEquipmentResponse> UnequipAsync(Guid userId, EquipmentSlotType slotType)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId)
            ?? throw new InvalidOperationException("Character not found.");

        var slot = await db.Set<EquipmentSlot>()
            .FirstOrDefaultAsync(s => s.CharacterId == characterId && s.SlotType == slotType);

        if (slot?.CharacterItemId != null)
        {
            var charItem = await db.Set<CharacterItem>().FindAsync(slot.CharacterItemId);
            if (charItem != null) charItem.IsEquipped = false;
            slot.CharacterItemId = null;
            slot.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
        }

        return await GetCharacterEquipmentAsync(userId);
    }

    public async Task<List<ItemDto>> GetCharacterInventoryAsync(Guid userId)
    {
        var characterId = await characterIdRead.GetCharacterIdAsync(userId);
        if (characterId == null) return [];

        var items = await db.Set<CharacterItem>()
            .Where(ci => ci.CharacterId == characterId)
            .Include(ci => ci.Item)
            .ToListAsync();

        return items.Select(ci => MapInventoryItemDto(ci)).ToList();
    }

    private static ItemDto MapItemDto(Item item) => new()
    {
        Id = item.Id,
        Name = item.Name,
        Description = item.Description,
        Icon = item.Icon,
        Rarity = item.Rarity.ToString(),
        SlotType = item.SlotType.ToString(),
        XpBonusPct = item.XpBonusPct,
        StrBonus = item.StrBonus,
        EndBonus = item.EndBonus,
        AgiBonus = item.AgiBonus,
        FlxBonus = item.FlxBonus,
        StaBonus = item.StaBonus,
        Category = item.Category.ToString(),
    };

    private static ItemDto MapInventoryItemDto(CharacterItem ci) => new()
    {
        Id = ci.Item.Id,
        Name = ci.Item.Name,
        Description = ci.Item.Description,
        Icon = ci.Item.Icon,
        Rarity = ci.Item.Rarity.ToString(),
        SlotType = ci.Item.SlotType.ToString(),
        XpBonusPct = ci.Item.XpBonusPct,
        StrBonus = ci.Item.StrBonus,
        EndBonus = ci.Item.EndBonus,
        AgiBonus = ci.Item.AgiBonus,
        FlxBonus = ci.Item.FlxBonus,
        StaBonus = ci.Item.StaBonus,
        CharacterItemId = ci.Id,
        IsEquipped = ci.IsEquipped,
        Category = ci.Item.Category.ToString(),
    };
}
