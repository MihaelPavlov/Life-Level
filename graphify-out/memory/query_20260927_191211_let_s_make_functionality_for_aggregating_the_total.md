---
type: "query"
date: "2026-09-27T19:12:11.603325+00:00"
question: "let's make functionality for aggregating the total steps for the user"
contributor: "graphify"
outcome: "useful"
source_nodes: ["ActivityController.cs", "ActivityService.cs", "ActivityDtos.cs", "activity_models.dart", "activity_service.dart", "activity_provider.dart", "home_hero_stage.dart", "invalidate_user_providers.dart", "ActivityServiceExternalItemGrantTests.cs"]
---

# Q: let's make functionality for aggregating the total steps for the user

## Answer

Implemented an authenticated GET /api/activity/summary endpoint. ActivityService resolves the user's character and sums persisted Activity.Steps into a 64-bit ActivitySummaryDto. Flutter adds ActivitySummary/service/provider, invalidates it after activity/sync/session refreshes, and Home replaces the 8,421 placeholder with the formatted all-time total. Backend aggregation tests and Home widget tests pass.

## Outcome

- Signal: useful

## Source Nodes

- ActivityController.cs
- ActivityService.cs
- ActivityDtos.cs
- activity_models.dart
- activity_service.dart
- activity_provider.dart
- home_hero_stage.dart
- invalidate_user_providers.dart
- ActivityServiceExternalItemGrantTests.cs