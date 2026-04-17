---
tags: [lifelevel, backend]
aliases: [Items Module, ItemService, Equipment]
---
# Items

> Owns item catalog, character inventory, equipment slots, and drop rules. Computes the aggregated gear bonus used by [[Activity]] for XP boosting.

## Entities

### Item (template)
```csharp
class Item {
  Guid Id;
  string Name, Description, Icon;
  Rarity Rarity;                // Common..Legendary
  ItemCategory Category;        // Tracker | Clothing | Footwear | Accessory
  SlotType SlotType;            // Head | Chest | Hands | Feet | Accessory
  int XpBonusPct;
  int StrBonus, EndBonus, AgiBonus, FlxBonus, StaBonus;
  DateTime CreatedAt;
}
```

### CharacterItem (instance in inventory)
```csharp
class CharacterItem {
  Guid Id, CharacterId, ItemId;
  DateTime AcquiredAt;
  bool IsEquipped;
}
```

### EquipmentSlot
```csharp
class EquipmentSlot {
  SlotType SlotType;
  Guid CharacterId;
  Guid? CharacterItemId;
  DateTime? EquippedAt, UpdatedAt;
}
```

One `EquipmentSlot` row per slot per character (5 rows).

### ItemDropRule
```csharp
class ItemDropRule {
  Guid Id;
  ItemSourceType SourceType;    // Boss | Chest | Dungeon
  Guid SourceId;                // specific boss/chest/dungeon Id
  Guid ItemId;
  int DropChancePct;
}
```

## ItemService (implements `IGearBonusReadPort`)

- `GetCharacterEquipmentAsync(userId)` → slots + items + totalBonuses
- `EquipItemAsync(userId, EquipItemRequest)` — moves item into slot, unequips previous
- `UnequipAsync(userId, slotType)` — removes from slot back to inventory
- `GetCharacterInventoryAsync(userId)` — unequipped items
- `GetEquippedBonusesAsync(userId)` → `GearBonusesDto` — **sum** of all equipped bonuses

## ItemGrantService

Called after boss defeats, chest opens, dungeon completes, and first-time external integration connects (Strava badge). Evaluates `ItemDropRule` entries:

1. Filter rules matching `(SourceType, SourceId)`.
2. For each rule, roll dice against `DropChancePct`.
3. If successful AND character has inventory space: create `CharacterItem`, fire `ItemObtainedNotifier` on mobile.
4. If inventory full: record a `BlockedItemInfo(itemName, itemIcon)` in the activity response — mobile shows `InventoryFullOverlay`.

## Inventory capacity port

`IInventorySlotReadPort.GetMaxInventorySlotsAsync(userId)` (implemented by [[Character]]) — used to check capacity before granting items.

## Seeded items

21 items total. Notable:
- **Strava Sync Badge** (Rare Tracker) — auto-granted on first Strava connect (no drop roll).

## Ports implemented
- `IGearBonusReadPort`

## Ports consumed
- `ICharacterIdReadPort`, `IInventorySlotReadPort`

## Endpoints
- `GET /api/items/equipment`
- `POST /api/items/equipment/equip`
- `DELETE /api/items/equipment/{slotType}`
- `GET /api/items/inventory`
- Admin: `/api/admin/items` — CRUD for Items + ItemDropRules

## Files
- `backend/src/modules/LifeLevel.Modules.Items/`

## Related
- [[Items and Equipment]]
- [[Activity]] (consumes gear XP bonus)
- [[Character]] (inventory slot capacity)
- [[Adventure.Encounters]] (chest / boss drops)
- [[Integrations]] (Strava badge)
