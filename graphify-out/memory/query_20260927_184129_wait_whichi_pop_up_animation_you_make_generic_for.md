---
type: "query"
date: "2026-09-27T18:41:29.528887+00:00"
question: "wait whichi pop up animation you make generic for the banked and shields i was talking about when i click on the task coin or gem we see pop up with coins rewards type description"
contributor: "graphify"
outcome: "useful"
source_nodes: ["reward_info_dialog.dart", "rewards_screen.dart", "home_hero_stage.dart", "home_hero_stage_navigation_test.dart"]
---

# Q: wait whichi pop up animation you make generic for the banked and shields i was talking about when i click on the task coin or gem we see pop up with coins rewards type description

## Answer

Corrected the popup choice: extracted the compact task reward-information dialog into shared RewardInfoData/showRewardInfoDialog, kept Rewards coin/gem/points/milestone taps on it, and changed Home Banked KM and Shields taps to use it. The chest-burst reveal remains separate from these Home info taps.

## Outcome

- Signal: useful

## Source Nodes

- reward_info_dialog.dart
- rewards_screen.dart
- home_hero_stage.dart
- home_hero_stage_navigation_test.dart