---
tags: [lifelevel, plan, achievements, rewards, flutter, backend]
aliases: [Reward Roads, Achievement Roads]
---

# Plan - Achievement Reward Roads

> Replace the flat achievements list with **Reward Roads**: one road per category, split into five stages (Common → Legendary). Every achievement now pays XP **+ coins + gems** and must be **claimed**. Claiming every achievement in a stage lets the player open that stage's **chest** (Wayfarer / Adept / Champion — the Shop chests), which reuses the task reward "You got loot!" popup. Design: artifact "Reward Roads Simplified" (claude.ai/artifact/8p7KjnJtLnL5FPUoz97DNd).

## Context
- Today `AchievementService.CheckUnlocksAsync` sets `UnlockedAt` and awards XP immediately — no claim step, no currency, no stages.
- 22 seeded achievements in 4 categories (`Running`, `Strength`, `Social` (streaks), `Raids`), tiers Common → Legendary.
- Currency ports already exist: `IRewardCurrencyPort` (coins, crystals = gems), `IShopWalletPort` (balance). Item grant: `ItemGrantService` / `IItemRewardGrantPort`. Shop chests pick a random unowned item of a rarity from the shop pool.
- Mobile: `AchievementsScreen` (opened from the shell) wraps the old `profile/tabs/achievements_tab.dart` list.

## Current Status
Implemented 2026-09-26 (backend + mobile), not yet committed or tried on a device.
- Backend: migration `AchievementRewardRoads`, endpoints `GET /api/achievements/roads`, `POST /api/achievements/{id}/claim`, `POST /api/achievements/claim-all[?category=]`, `POST /api/achievements/stages/{category}/{tier}/open`; tests `AchievementRoadsTests` (6).
- Mobile: `features/achievements/roads/` (hub, road screen, widgets, fx), popup takes `chestAsset` + custom tile icons; tests `test/features/achievements/reward_roads_test.dart` (3).
- Pre-existing failures unrelated to this work: `rewards_screen_test.dart` (3) and `visual/app_screen_goldens_test.dart` (4) fail on the previous commit too.

## Rules
| Tier | Achievement reward (on claim) | Stage chest | Chest bonus |
|---|---|---|---|
| Common | XP + 50 coins + 1 gem | Wayfarer (Common item) | 200 coins + 2 gems |
| Uncommon | XP + 150 coins + 3 gems | Wayfarer (Common item) | 500 coins + 5 gems |
| Rare | XP + 400 coins + 8 gems | Adept (Rare item) | 1,000 coins + 10 gems |
| Epic | XP + 1,000 coins + 20 gems | Adept (Rare item) | 2,000 coins + 20 gems |
| Legendary | XP + 2,500 coins + 50 gems | Champion (Legendary item) | 5,000 coins + 50 gems |

- **Unlock ≠ claim.** Unlocking sets `UnlockedAt` only. `POST claim` pays XP + coins + gems and sets `ClaimedAt`.
- **Existing players:** achievements already unlocked were already paid XP → migration sets `ClaimedAt = UnlockedAt`. Their completed stages' chests become openable.
- **Stage** = achievements of one category + tier. Stages are not gated; progress on all of them counts. A stage with no achievements is skipped.
- **Chest ready** when every achievement in the stage is claimed. Opening grants a random unowned item of the chest rarity (shop pool) + the chest bonus. No unowned item / inventory full → item is skipped, the bonus is still paid. Each stage chest opens once.
- **Current stage** of a road = first stage (tier order) whose chest is not opened.

## Backend
Files to modify / add:
- `Domain/Entities/Achievement.cs` — `CoinReward`, `GemReward`.
- `Domain/Entities/UserAchievement.cs` — `ClaimedAt`, `IsClaimed`.
- `Domain/Entities/UserAchievementStageChest.cs` (new) — `UserId`, `Category`, `Tier`, `OpenedAt`, `ItemId?`, `Coins`, `Gems`; unique (UserId, Category, Tier).
- `Domain/AchievementRewardTable.cs` (new) — the table above, one place.
- `Application/UseCases/AchievementService.cs` — unlock without paying; `GetRoadsAsync`, `ClaimAsync`, `ClaimAllAsync`, `OpenStageChestAsync`.
- `Application/DTOs/AchievementDtos.cs` — road / stage / claim / chest DTOs; `AchievementDto` gains reward + claim fields.
- `SharedKernel/Ports/IChestItemRewardPort.cs` (new) + Items adapter — pick + grant a random unowned shop-pool item of a rarity.
- `LifeLevel.Api/Controllers/AchievementsController.cs` — `GET roads`, `POST {id}/claim`, `POST claim-all`, `POST stages/{category}/{tier}/open`.
- `AchievementSeeder.cs` — coin/gem rewards in the catalog.
- Migration `AchievementRewardRoads` — columns, table, data backfill (rewards by tier, `ClaimedAt = UnlockedAt`).

## Mobile
- `features/achievements/models/achievement_models.dart` — `AchievementRoad`, `AchievementStage`, claim/chest results; `AchievementDto` reward/claim fields.
- `services` + `providers` — `achievementRoadsProvider` (roads + wallet), claim / claim-all / open-chest calls.
- `screens/reward_roads_hub_screen.dart` — Ready bar (Claim all), Continue card, 2-column roads grid.
- `screens/reward_road_screen.dart` — header wallet, stage stepper, current stage card (8-piece bar + chest), Ready to claim, In progress, Done row, Up next.
- Claim animation — row stamp + ring, coins/gems fly to the header wallet (`RewardFx`), XP floats, counters count up, rows fold, stage bar pieces pop green.
- Chest — when the stage chest is ready: card glows, chest hops; opening uses `showTaskRewardPopup` with a new optional `chestAsset` (stage chest art) and item/coin/gem tiles; afterwards the road advances to the next stage (stepper + card slide in).
- `achievements_screen.dart` hosts the hub; old `profile/tabs/achievements_tab.dart` is removed.

## Verification
- Backend unit tests (`AchievementRoadsTests`): unlock doesn't pay; claim pays XP+coins+gems once; claim-all; chest not openable until the stage is claimed; chest opens once, grants an unowned item of the right rarity + bonus; migration backfill shape via service.
- `flutter analyze`, widget tests for hub/road rendering with motion off.
- Manual: `/phone-test` — claim one, claim all, complete a stage, open its chest.
