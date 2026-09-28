---
type: "query"
date: "2026-09-27T19:52:15.440234+00:00"
question: "Does the level-up thing show unlocks that are 100% real?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["level_up_overlay.dart", "level_up_notifier.dart", "ActivityService.cs", "CharacterService.cs", "ZoneUnlockReadPortAdapter.cs", "ItemGrantService.cs"]
---

# Q: Does the level-up thing show unlocks that are 100% real?

## Answer

Not 100%. The level itself is real and persisted from backend XP thresholds. For activity-triggered level-ups, displayed item rewards are granted to inventory and base stat points are persisted. Zone tiles are queried by LevelRequirement crossed but do not themselves create UserZoneUnlock records, so they are level-eligible rather than necessarily accessible. Configured bonus stat points are granted but omitted from the displayed count; configured titles and inventory-slot increases are granted but not displayed. Level-ups originating from season claims or generic profile refresh send no unlock payload and show only the neutral fallback. Therefore the overlay is partially real but incomplete and the zone wording can overstate access.

## Outcome

- Signal: useful

## Source Nodes

- level_up_overlay.dart
- level_up_notifier.dart
- ActivityService.cs
- CharacterService.cs
- ZoneUnlockReadPortAdapter.cs
- ItemGrantService.cs