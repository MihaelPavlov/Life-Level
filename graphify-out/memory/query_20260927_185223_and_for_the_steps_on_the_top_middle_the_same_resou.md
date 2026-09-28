---
type: "query"
date: "2026-09-27T18:52:23.470851+00:00"
question: "and for the steps on the top middle the same resource INfo data. Also are these steps caunt real ?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["home_hero_stage.dart", "currency_chip.dart", "health_sync_service.dart", "activity_models.dart"]
---

# Q: and for the steps on the top middle the same resource INfo data. Also are these steps caunt real ?

## Answer

Added the shared ResourceInfoData popup to the Home Steps chip. The displayed 8,421 count is not real: it is explicitly a static placeholder. Activity entities store per-activity steps and Health sync reads daily steps, but Home currently has no provider/API exposing today's total.

## Outcome

- Signal: useful

## Source Nodes

- home_hero_stage.dart
- currency_chip.dart
- health_sync_service.dart
- activity_models.dart