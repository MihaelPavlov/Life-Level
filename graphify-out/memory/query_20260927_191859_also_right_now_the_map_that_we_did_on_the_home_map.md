---
type: "query"
date: "2026-09-27T19:18:59.247115+00:00"
question: "also right now the map that we did on the home map section currently if we click on the map from the bottom nav we do not want to be navigate to the opened current zone just to the current zone position"
contributor: "graphify"
outcome: "useful"
source_nodes: ["main_shell.dart", "world_hub_screen.dart", "region_detail_screen.dart"]
---

# Q: also right now the map that we did on the home map section currently if we click on the map from the bottom nav we do not want to be navigate to the opened current zone just to the current zone position

## Answer

Bottom-nav Map now clears explicit target IDs, WorldHub honors autoOpenActiveRegion to open the active region, and RegionDetail scrolls to the active/current zone with no initialZoneId so no details sheet opens. Home map CTAs remain direct-target and continue opening their selected zone details.

## Outcome

- Signal: useful

## Source Nodes

- main_shell.dart
- world_hub_screen.dart
- region_detail_screen.dart