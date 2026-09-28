---
type: "query"
date: "2026-09-27T18:20:17.281820+00:00"
question: "does the pop up on rewards tab on click coins gems and other rewards, are generic can we use it for other things?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["task_reward_popup.dart", "rewards_screen.dart", "road_fx.dart"]
---

# Q: does the pop up on rewards tab on click coins gems and other rewards, are generic can we use it for other things?

## Answer

Expanded from original query via graph vocab: [reward, rewards, popup, dialog, coin, coins, gem, gems, item, task, chest, overlay]. showTaskRewardPopup is data-driven and already reused by achievement stage chests. TaskRewardItem accepts an asset or arbitrary icon widget plus label and color; the popup accepts subtitle, alternate chest art, and title/hint toggles. It is reusable for loot-style reward reveals, but not fully generic: it lives under features/rewards, uses Task-prefixed names, has a fixed chest animation and fixed 'You got loot!' title, lays every reward in one horizontal row, and only returns landing metadata for non-empty asset strings, excluding arbitrary custom icon widgets from follow-on flight animations.

## Outcome

- Signal: useful

## Source Nodes

- task_reward_popup.dart
- rewards_screen.dart
- road_fx.dart