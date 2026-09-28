---
type: "query"
date: "2026-09-27T18:35:49.614521+00:00"
question: "let's make the actual hero on the gear to be visualized the same way on the home page, SO with the equipred items if they are visible"
contributor: "graphify"
outcome: "useful"
source_nodes: ["home_hero_stage.dart", "gear_paperdoll.dart", "items_provider.dart", "home_hero_stage_navigation_test.dart"]
---

# Q: let's make the actual hero on the gear to be visualized the same way on the home page, SO with the equipred items if they are visible

## Answer

HomeHeroStage now watches equipmentProvider and renders the shared GearPaperDoll inside its existing floating animation. It uses gearBaseRender while equipment loads and displays the same supported equipped Legs/Chest layers or server gearImageUrl as GearScreen. Added focused widget coverage.

## Outcome

- Signal: useful

## Source Nodes

- home_hero_stage.dart
- gear_paperdoll.dart
- items_provider.dart
- home_hero_stage_navigation_test.dart