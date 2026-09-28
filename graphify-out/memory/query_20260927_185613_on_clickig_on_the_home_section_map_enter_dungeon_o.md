---
type: "query"
date: "2026-09-27T18:56:13.000713+00:00"
question: "ON clickig on the home section map enter dungeon on all of them we are navigated to the world , not to the zone. So if we have selected zone we want on click enter dungeon and the other types of home section map to be naviate to the particular place region zone"
contributor: "graphify"
outcome: "useful"
source_nodes: ["world_map_notifier.dart", "main_shell.dart", "home_portal_card.dart", "world_hub_screen.dart", "region_detail_screen.dart", "home_portal_card_test.dart"]
---

# Q: ON clickig on the home section map enter dungeon on all of them we are navigated to the world , not to the zone. So if we have selected zone we want on click enter dungeon and the other types of home section map to be naviate to the particular place region zone

## Answer

Extended WorldMapOpenRequest with explicit regionId and zoneId. All non-boss Home portal CTAs now pass the represented zone. MainShell forwards the target to WorldHubScreen, which opens the specified region; RegionDetailScreen scrolls to and opens the exact zone sheet. Added a dungeon CTA targeting regression test; the full Home portal suite passes.

## Outcome

- Signal: useful

## Source Nodes

- world_map_notifier.dart
- main_shell.dart
- home_portal_card.dart
- world_hub_screen.dart
- region_detail_screen.dart
- home_portal_card_test.dart