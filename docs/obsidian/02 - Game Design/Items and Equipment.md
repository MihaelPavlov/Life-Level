---
tags: [lifelevel, game-design]
aliases: [Items, Equipment, Gear, Loot]
---
# Items and Equipment

> Items give permanent passive bonuses — XP % multipliers and stat buffs. Earned from boss kills, chest opens, dungeon completions, or external integrations.

## Rarity tiers (5)

| Rarity | UI color | Typical source |
|--------|----------|----------------|
| Common | Green | Chests, early bosses |
| Uncommon | Blue | Mid-game chests |
| Rare | Purple | Bosses, Strava-connect reward |
| Epic | Orange | Hard bosses, dungeon bosses |
| Legendary | Red | End-game bosses, 30-day streak milestone |

## Item entity

```csharp
class Item {
  Guid Id;
  string Name, Description, Icon;
  Rarity Rarity;
  ItemCategory Category;        // Tracker, Clothing, Footwear, Accessory
  SlotType SlotType;            // Head, Chest, Hands, Feet, Accessory
  int XpBonusPct;               // +X% XP on activities
  int StrBonus, EndBonus, AgiBonus, FlxBonus, StaBonus;
}
```

## Equipment slots (5)

| Slot | Stored in |
|------|-----------|
| Head | `EquipmentSlot` row |
| Chest | `EquipmentSlot` row |
| Hands | `EquipmentSlot` row |
| Feet | `EquipmentSlot` row |
| Accessory | `EquipmentSlot` row |

Equipping an item moves it from inventory to the slot and unequips whatever was there (back to inventory).

## Bonus stacking

`IGearBonusReadPort.GetEquippedBonusesAsync(userId)` returns the **sum** of all equipped items' bonuses:

```csharp
GearBonusesDto {
  int XpBonusPct;     // applied to activity XP: xp *= (1 + pct/100)
  int StrBonus, EndBonus, AgiBonus, FlxBonus, StaBonus;
}
```

Gear stats are displayed as chips on the profile page stat cards (e.g. "STR 45 (+5)") and the XP bonus is shown as a chip on the activity logging screen.

## Drop rules

`ItemDropRule` entity:

```csharp
class ItemDropRule {
  Guid Id;
  ItemSourceType SourceType;   // Boss, Chest, Dungeon
  Guid SourceId;               // the boss/chest/dungeon id
  Guid ItemId;
  int DropChancePct;
}
```

`ItemGrantService` evaluates drop rules after activity / level-up / boss-defeat events. If inventory is full: the drop is **blocked** and the mobile app shows the `InventoryFullOverlay` with the item icon + unlock hint (e.g. "Level 10 → 40 slots").

## Inventory capacity

Max slots scale with level:

| Level | Max slots |
|-------|-----------|
| 1–4 | 20 |
| 5–9 | 30 |
| 10–14 | 40 |
| 15–24 | 50 |
| 25–34 | 60 |
| 35–49 | 75 |
| 50+ | 100 |

Backend port: `IInventorySlotReadPort.GetMaxInventorySlotsAsync(userId)`.

## Current catalog

21 items as of the 2026-04-02 changelog (expanded from 8). Categories: Tracker, Clothing, Footwear, Accessory.

Notable seeded items:
- **Strava Sync Badge** (Rare Tracker) — auto-awarded on first Strava connect

## Endpoints

- `GET /api/items/equipment` — `CharacterEquipmentResponse(slots[], totalBonuses)`
- `POST /api/items/equipment/equip` — body: `EquipItemRequest(characterItemId, slotType)`
- `DELETE /api/items/equipment/{slotType}` — unequip
- `GET /api/items/inventory` — unequipped items

## Related
- [[Items]] (backend module)
- [[Feature - Items]] (mobile)
- [[Character System]]
- [[XP and Leveling]]
- [[Strava]] (Strava Sync Badge reward)
