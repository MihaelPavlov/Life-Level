---
type: "query"
date: "2026-09-27T19:15:59.612648+00:00"
question: "LETs add again resourceINfoDAta for the gear , power str, health,shield and coins"
contributor: "graphify"
outcome: "useful"
source_nodes: ["gear_screen.dart", "gear_stats_row.dart", "resource_info_dialog.dart", "gear_stats_resource_info_test.dart"]
---

# Q: LETs add again resourceINfoDAta for the gear , power str, health,shield and coins

## Answer

Added shared ResourceInfoData dialogs to Gear Power, sword/Strength, Health, shield/Defense, and Coins. Each display is now an accessible tap target with a descriptive title, explanation, and destination; live values remain on the Gear screen. Added focused widget coverage for all four combat stats.

## Outcome

- Signal: useful

## Source Nodes

- gear_screen.dart
- gear_stats_row.dart
- resource_info_dialog.dart
- gear_stats_resource_info_test.dart