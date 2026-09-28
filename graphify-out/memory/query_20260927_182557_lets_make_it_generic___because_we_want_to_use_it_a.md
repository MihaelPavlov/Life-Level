---
type: "query"
date: "2026-09-27T18:25:57.254416+00:00"
question: "lets make it generic , because we want to use it also for banked km on home page on click, shiels,"
contributor: "graphify"
outcome: "useful"
source_nodes: ["task_reward_popup.dart", "home_hero_stage.dart", "rewards_screen.dart", "road_fx.dart"]
---

# Q: lets make it generic , because we want to use it also for banked km on home page on click, shiels,

## Answer

Generalized the task reward popup into showRewardRevealPopup with RewardRevealItem, customizable title, hero art, close hint, and flight keys. Migrated rewards and achievement chests, and wired home banked distance and streak shield chips to the same reveal.

## Outcome

- Signal: useful

## Source Nodes

- task_reward_popup.dart
- home_hero_stage.dart
- rewards_screen.dart
- road_fx.dart