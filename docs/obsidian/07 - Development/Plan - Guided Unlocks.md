# Plan - Guided Unlocks

Status: implemented 2026-09-30 (backend + mobile). Pacing replaced on 2026-10-03 by [[Plan - Unlock Path]] (levels per feature, at most two per level, tours pay coins).

Design source: https://claude.ai/artifact/KFGW2gUGBsogt1zpKjXu3h ("Unlock it, then learn it right there").

Test plan: [[Test Plan - Guided Feature Unlocks]].

## Context
Every feature unlocks through play. The unlock plays a short ceremony ("NEW FEATURE UNLOCKED"), then offers
**Show me**, which opens the feature with a 2–3 stop spotlight tour ending in its main action, or **Later**,
which leaves a NEW pill and runs the same tour on the first visit. This replaces the intro modal, the six
Home bubbles, the outro and the 8-step Map tutorial.

## The chain
| # | Key | Trigger (derived from state) | Unlocks | Tour |
|---|-----|-----------------------------|---------|------|
| 0 | `home` | Onboarding done | Home | hero → Adventure Hub |
| 1 | `achievements` | ≥ 1 activity logged | Hub tile | Continue card → All roads → Claim all |
| 2 | `map` | Distance travelled on the world map > 0 | Map button (raised orb) | orb (tap) → journey card → View on map |
| 3 | `gear` | ≥ 1 item owned | Gear tab + Home mount/weapon cards | slots → combat stats → tap the item |
| 4 | `chests` | Reached a zone beyond the start (≥ 2 zones unlocked) | Hub tile | region banner → rewards → next region |
| 5 | `talents` | Level ≥ 3 | Hub tile | crystals → grid → Card Draw |
| 6 | `shields` | Longest streak ≥ 3 | Streak shields | streak header → shields → Claim reward |
| 7 | `bosses` | A boss spawned for the user | Hub tile | boss card → HP + my damage → Enter Battle |
| 8 | `ranks` | First rank above Novice (1 boss defeated) or first earned title (the tutorial's Novice Adventurer title doesn't count) | Hub tile (Ranks) | rank ladder → a locked title → Equip the first earned title |
| 9 | `guild` | Level ≥ 5 | Hub tile | member limit → Create → Find |
| 10 | `leaderboard` | Level ≥ 6 | Hub tile | Global / Region / Guild tabs → your row + rank-up chest → tap a board |
| 11 | `modes` | Level ≥ 10 | Mode tab (Burn Chain) | Burn Chain → locked Treasure Delve → start chain |
| 12 | `delve` | Level ≥ 15 | Treasure Delve banner | banner → runs → enter the vault |

## Backend
- **Entity** `CharacterUnlock` (Character module): `Id, UserId, Key, UnlockedAt, SeenAt?, TouredAt?`. Unique `(UserId, Key)`.
- **Facts port** `IUnlockFactsReadPort` (SharedKernel) → `UnlockFacts(ActivityCount, HasTravelled, ItemCount, ZonesReached, Level, LongestStreak, BossSeen, OnboardingDone)`.
  Adapter `UnlockFactsReadAdapter` in `LifeLevel.Api/Infrastructure/Persistence` queries `AppDbContext` (same pattern as `TaskEligibilityReadAdapter`).
- **Service** `UnlockService` (Character module): `GetAsync` evaluates the catalog, inserts rows for newly met conditions and returns the list.
  **Back-fill:** the first evaluation for a user marks everything already met as seen + toured (silent), except `home` for a user with no activities.
  `MarkSeenAsync(key)`, `MarkTouredAsync(key)` (+25 XP once via `ICharacterXpPort`).
- **API** `GET /api/unlocks`, `POST /api/unlocks/{key}/seen`, `POST /api/unlocks/{key}/toured`.
- State-derived, not event-driven: a lost event can't lose an unlock, and back-fill needs no migration script.

## Mobile
- `features/unlocks/`: models, service, `unlocksProvider`, `isUnlocked(key)` helpers.
- **Locks:** hub tiles (dashed, silhouette, lock badge; name stays visible), Gear + Mode tabs, Map orb, Delve banner, Home mount/weapon `?` cards.
- **Ceremony** overlay in the shell: queued unseen unlocks → silhouette + padlock shake/break → icon (no frame) with rays → Show me / Later → icon flies to its slot.
- **Tour engine** `features/unlocks/tour/`: `TourTarget(id)` registers a widget; `FeatureTour.run(steps)` draws the dim + hole + bubble. Tap steps let the tap through to the real widget and advance on it. Ends with the "explored · +25 XP" card and `POST toured`.
- The old tutorial (intro/outro modals, Home bubbles, map tutorial) stops running; Profile → Tutorials lists toured features for replay.

## Verification
- Backend unit tests for `UnlockService` (thresholds, back-fill, idempotency, XP once).
- Mobile tests: unlock gating of hub/nav, tour engine (next, skip, tap-through), ceremony queue.

## What shipped (2026-09-30)
- **Back-fill rule changed:** silent back-fill applies only to characters created before `UnlockService.BackFillBefore` (2026-09-30 UTC). A new player whose onboarding import already meets several conditions gets every ceremony (Home tour first, then one ceremony at a time). `UnlockFacts` gained `CharacterCreatedAt`.
- **Mobile (`features/unlocks/`):**
  - `models/` (`UnlocksSnapshot`, `kUnlockCatalog`), `services/unlocks_service.dart`, and the existing `unlocksProvider`.
  - `unlock_coordinator.dart` (in `MainShell`) queues ceremonies. It waits for level-ups, open overlays and sheets to finish, and refreshes on world-zone changes.
  - `widgets/unlock_ceremony.dart`: padlock shake and shatter, then Show me / Later.
  - `widgets/unlock_badges.dart`: `LockBadge`, `NewPill`, and the locked-tap hint toast.
- **Tour engine (`tour/`):**
  - `TourTarget(id)` marks real widgets. `FeatureTour.run` draws the spotlight on the root overlay, and tap stops let the tap through to the real widget.
  - Stops whose widget is missing are skipped.
  - Finishing or skipping marks the feature toured (+25 XP once).
  - `TourOnFirstVisit` runs the tour when a screen opens for the first time after its unlock.
  - Tab, Map-button and Home tours run from the shell (`_openUnlockedFeature`).
- **Locks:**
  - Adventure Hub tiles for Achievements, Region Chests, Talents, Bosses and Guild. Locked tiles are dashed and sorted last; a fresh tile leads the row with a NEW pill.
  - The Gear and Mode tabs and the Map button.
  - The mount and weapon `?` cards and the Shields chip on Home.
  - The Treasure Delve banner.
- **Old tutorial removed:** `features/tutorial/` is deleted. Profile → Tutorials is now `ExploredFeaturesScreen`, which replays a tour with no XP.
- **Tests:**
  - Backend: `UnlockServiceTests`, now including `NewPlayerWithImportedHistory_GetsEveryCeremony`.
  - Mobile: `test/features/unlocks/` (models, tour engine, hub locks, coordinator).

## Added 2026-10-01: Titles & Ranks and Leaderboard
- **Backend:** `UnlockFacts` gained `TitlesEarned` (count of `CharacterTitle` rows, excluding Novice Adventurer) and `RankReached` (`Character.Rank` ≠ Novice). `UnlockService.Catalog` has `ranks` after `bosses` and `leaderboard` after `guild`. Tests: `Ranks_OpenOnFirstRankOrTitle`, plus Level 5/6 leaderboard thresholds.
- **Mobile:** the Ranks and Leaderboard hub tiles are gated (`UnlockKeys.ranks`, `UnlockKeys.leaderboard`). The Titles & Ranks overlay and the Leaderboard route are wrapped in `TourOnFirstVisit`, and `_openUnlockedFeature` routes both keys. Tour targets: `titles.rank`, `titles.locked`, `titles.equip` (the first earned title that isn't equipped; skipped when there is none) and `leaderboard.scopes`, `leaderboard.you`, `leaderboard.metrics`.
- **Existing accounts:** back-fill only runs for a user with no unlock rows yet, so an account that already has rows and qualifies gets the two new ceremonies once.

## Audit 2026-10-01 (app vs design)
- **Checked and matching:** every `TourIds` target is placed on a real widget. All locks are in place (hub tiles, Gear/Mode tabs, Map button, Shields chip, `?` cards, Delve banner). Ceremony copy, Profile → Tutorials replay and the unlock refresh triggers (level-up, item, world zone/boss, manual log, sync, resume) all match the design.
- **Home tour is 2 stops (hero → Adventure Hub).** The stop on the Log workout button was removed from the app and the design, because that button is temporary (`kAlwaysShowLogWorkout`). The pull-to-import hint moved into the hero stop.
- **Copy:** the design was synced to the app's tour copy, which is the source of truth (Map step 3 is the journey's action button, not "View on map").
- **Back-fill for keys added later:** left as is (see above).
