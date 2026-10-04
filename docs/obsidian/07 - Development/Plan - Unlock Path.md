# Plan - Unlock Path

Status: implemented 2026-10-03 (backend + mobile), not yet committed. Migration `UnlockActivityCountAtUnlock` not yet applied.

Design source: https://claude.ai/artifact/4ccuxMLNW6UyWw5Jnawhxc ("One level, two features at most").

Builds on [[Plan - Guided Unlocks]]: the ceremonies, tours and locks stay. What changes is the pacing.

## Why
- Setup paid a 500 XP starter bonus, which passes Level 2 (300 XP). A player with no workouts opened Home at LV 2.
- One workout could unlock Achievements, Map, Gear and Region Chests at once. Each tour paid +25 XP, which could reach Level 3 and add Talents to the same queue.
- The Map tour never explained the BANKED chip.
- A level-up (often from tour XP) could open on top of a ceremony or tour, so the second unlock looked skipped.

## The path
| Level | Features | Action needed besides the level |
|---|---|---|
| 1 | Home, Map & Banked km | Setup; first km |
| 2 | Achievements, Gear | A workout; an item |
| 3 | Talents, Streak Shields | —; 3-day streak |
| 4 | Region Chests, Bosses | Second zone; a boss appears |
| 5 | Titles & Ranks | First rank or title |
| 6 | Leaderboard | — |
| 8 | Guild | — |
| 10 | Game Modes | — |
| 15 | Treasure Delve | — |

## Backend
- `UnlockService.Definition(Key, Tier, Action)`, `IsMet = Level ≥ Tier && Action`. Catalog is ordered by tier. `UnlockDto` carries `Tier`.
- **Pacing** (`UnlockService.Releasable`, not for back-filled legacy players): only the lowest met tier is released, and only when no earlier ceremony is unseen and one of these is true:
  - it is tier 1,
  - a feature of the same tier is already out (its partner caught up),
  - a workout was logged since the last release.
- `CharacterUnlock.ActivityCountAtUnlock` stores the workout count at release (new migration).
- Tours pay `TourCoins = 25` through `IRewardCurrencyPort`. `UnlockTouredResponse(Key, XpAwarded = 0, CoinsAwarded)`.
- `CharacterService.SetupAsync` no longer awards starter XP.
- `OnboardingImportService.HistoryXpCap = 900` (start of Level 3).

## Mobile
- `UnlockMeta.tier` / `need`, `unlocksAtLevel`, `unlocksBetweenLevels`. Locked hints name the level ("Reach Level 2 and find an item").
- `UnlockCoordinator` plays one moment as a queue: ceremony 1 of 2 → (Show me tour, waits until the screen and tour are done) → `showUnlockBridge` ("1 more unlock") → ceremony 2 of 2. Unlock refreshes wait 1.2 s so a level-up from the same workout goes first. `unlockMomentRunning` is set for the whole moment.
- `showUnlockCeremony(queue:, index:)` shows the "UNLOCK 1 OF 2" counter and "Later · 1 more unlock waiting".
- `MainShell._checkPendingLevelUps` waits while a ceremony, a moment or a tour is running.
- The level-up screen lists the features of the levels gained ("NEW FEATURE · Opens now" or "Opens when you …").
- Tours: Home has 3 stops (hero, hub, locked Map button). Map has 4 (`home.banked` chip → Map button → journey card → Travel). The next-zone journey card's Travel button now says "Travel · X km banked →" and carries the `journey.viewOnMap` tour target.
- The explored card shows "+25 coins".
- `HomeNextUnlockCard` under the Adventure Hub shows the next level's features, with either the XP to go or the action they wait for.

## Tests
- Backend: `UnlockServiceTests` (tiers, actions wait for their level, one tier per workout, a partner opening without a workout, imported history gets tier 1 first, coins not XP), `ImportFirstOnboardingTests` (no starter XP, import capped at Level 3).
- Mobile: `unlock_coordinator_test` (1 of 2 queue with the bridge), `unlock_models_test` (tiers match the server, at most two per level, next unlock).

## Open
- Leaderboard (Level 6) opens before Guild (Level 8), so its Guild tab is empty until then. Decide whether to hide that tab or show it locked.
- Accounts created after 2026-09-30 keep the unlock rows they already have. Only new releases follow the pacing.
