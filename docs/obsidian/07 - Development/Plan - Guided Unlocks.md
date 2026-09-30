# Plan - Guided Unlocks

Status: in progress (2026-09-30).

Design source: https://claude.ai/artifact/KFGW2gUGBsogt1zpKjXu3h ("Unlock it, then learn it right there").

## Context
Every feature unlocks through play. The unlock plays a short ceremony ("NEW FEATURE UNLOCKED"), then offers
**Show me**, which opens the feature with a 2–3 stop spotlight tour ending in its main action, or **Later**,
which leaves a NEW pill and runs the same tour on the first visit. This replaces the intro modal, the six
Home bubbles, the outro and the 8-step Map tutorial.

## The chain
| # | Key | Trigger (derived from state) | Unlocks | Tour |
|---|-----|-----------------------------|---------|------|
| 0 | `home` | Onboarding done | Home | hero → Log workout → Adventure Hub |
| 1 | `achievements` | ≥ 1 activity logged | Hub tile | Continue card → All roads → Claim all |
| 2 | `map` | Distance travelled on the world map > 0 | Map button (raised orb) | orb (tap) → journey card → View on map |
| 3 | `gear` | ≥ 1 item owned | Gear tab + Home mount/weapon cards | slots → combat stats → tap the item |
| 4 | `chests` | Reached a zone beyond the start (≥ 2 zones unlocked) | Hub tile | region banner → rewards → next region |
| 5 | `talents` | Level ≥ 3 | Hub tile | crystals → grid → Card Draw |
| 6 | `shields` | Longest streak ≥ 3 | Streak shields | streak header → shields → Claim reward |
| 7 | `bosses` | A boss spawned for the user | Hub tile | boss card → HP + my damage → Enter Battle |
| 8 | `guild` | Level ≥ 5 | Hub tile | member limit → Create → Find |
| 9 | `modes` | Level ≥ 10 | Mode tab (Burn Chain) | Burn Chain → locked Treasure Delve → start chain |
| 10 | `delve` | Level ≥ 15 | Treasure Delve banner | banner → runs → enter the vault |

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
