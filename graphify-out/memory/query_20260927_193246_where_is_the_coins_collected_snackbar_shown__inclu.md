---
type: "query"
date: "2026-09-27T19:32:46.516259+00:00"
question: "Where is the coins collected snackbar shown, including claim daily streak reward?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["streak_detail_sheet.dart", "rewards_screen.dart", "reward_road_screen.dart", "app_toast.dart"]
---

# Q: Where is the coins collected snackbar shown, including claim daily streak reward?

## Answer

Coin-related success notifications are shown in three flows: StreakDetailSheet claim reward shows '+N coins claimed!'; RewardsScreen task claim fallback (when reward FX is disabled or there are no claimable rows) shows 'N tasks claimed · N coins, N crystals'; Achievement RewardRoadScreen has its own custom road toast after claiming achievements and can include coin amounts. Daily/weekly milestone claiming itself has no coin snackbar. Error toasts are separate and should remain.

## Outcome

- Signal: useful

## Source Nodes

- streak_detail_sheet.dart
- rewards_screen.dart
- reward_road_screen.dart
- app_toast.dart