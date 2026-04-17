---
tags: [lifelevel, mobile]
aliases: [Items Feature, Equipment, Inventory]
---
# Feature — Items

> Equipment paperdoll + inventory grid. Tap a slot to swap gear; tap an inventory item to equip/discard/inspect.

## Files

```
lib/features/items/
├── models/
│   └── item_models.dart
├── services/
│   └── items_service.dart
└── providers/
    └── items_provider.dart
```

UI widgets live in [[Feature - Profile]] under `profile/tabs/equipment_tab.dart` and `profile/tabs/inventory_tab.dart`.

## item_models.dart

```dart
class ItemDto {
  String id, name, description, icon;
  String rarity;             // 'Common' | 'Uncommon' | 'Rare' | 'Epic' | 'Legendary'
  String slotType;           // 'Head' | 'Chest' | 'Hands' | 'Feet' | 'Accessory'
  int xpBonusPct;
  int strBonus, endBonus, agiBonus, flxBonus, staBonus;
  String? characterItemId;   // instance id if owned
  bool isEquipped;
  String category;           // 'Tracker' | 'Clothing' | 'Footwear' | 'Accessory'
}

class CharacterEquipmentResponse {
  List<EquipmentSlot> slots;
  List<ItemDto> items;
  GearBonusesDto bonuses;
}

class EquipmentSlot {
  String type;
  ItemDto? equippedItem;
}

class InventoryResponse {
  List<ItemDto> items;
  int maxSlots, usedSlots;
}

class GearBonusesDto {
  int strBonus, endBonus, agiBonus, flxBonus, staBonus, xpBonusPct;
}
```

## ItemsService

```dart
Future<CharacterEquipmentResponse> getEquipment();
Future<CharacterEquipmentResponse> equipItem(String characterItemId, String slotType);
Future<CharacterEquipmentResponse> unequip(String slotType);
Future<InventoryResponse> getInventory();
```

## Providers

```dart
final equipmentProvider = AsyncNotifierProvider<EquipmentNotifier, CharacterEquipmentResponse>(...);
final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, InventoryResponse>(...);
```

## Rarity colours (mobile palette)

| Rarity | Color |
|--------|-------|
| Common | Green (`AppColors.green`) |
| Uncommon | Blue |
| Rare | Purple (`AppColors.purple`) |
| Epic | Orange (`AppColors.orange`) |
| Legendary | Red (`AppColors.red`) |

## Inventory UX

- **70% full** → yellow warning banner
- **100% full** → red warning + blocked-item overlay on future grants (`InventoryFullNotifier`)
- Item detail sheet shows stat bonuses, XP bonus chip, rarity ribbon, equip/discard actions

## Related
- [[Items and Equipment]]
- [[Items]] (backend)
- [[Feature - Profile]] (renders the paperdoll and grid)
- [[Global Event Pattern]] (ItemObtainedNotifier + InventoryFullNotifier)
