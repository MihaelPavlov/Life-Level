---
type: "query"
date: "2026-09-27T18:07:14.430201+00:00"
question: "currenthly we have new redesign over the achivments, so can we check if the implemented there is full and working with the new chests ?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["AchievementService", "AchievementRoadsTests", "ChestItemRewardPortAdapter", "achievementRoadsProvider", "reward_road_screen.dart"]
---

# Q: currenthly we have new redesign over the achivments, so can we check if the implemented there is full and working with the new chests ?

## Answer

Expanded from original query via graph vocab: [achievement, achievements, chest, chests, reward, rewards, claim, claimed, rarity, inventory, unlock]. Audit found the Reward Roads redesign implemented end to end with migration, APIs, claim rewards, stage chests, shop-pool rarity grants, Flutter hub/road UI and animation coverage. Six backend tests and three achievement widget tests pass. It is not fully production-safe: claim state and chest-open state are committed before downstream XP/currency/item payouts, so a payout exception can permanently mark a claim/chest consumed; the mobile notifier invalidates characterProfileProvider but not inventoryProvider after a granted chest item. No real HTTP/database or physical-device end-to-end test was present.

## Outcome

- Signal: useful

## Source Nodes

- AchievementService
- AchievementRoadsTests
- ChestItemRewardPortAdapter
- achievementRoadsProvider
- reward_road_screen.dart