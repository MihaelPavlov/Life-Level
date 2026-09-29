# Plan - Import-First Onboarding

Implements the approved prototype (claude.ai/artifact/WgewNiBHGEVSDPdqUDBf19): a new player connects a tracker, their last 30 days become XP and a starting level, and the class is **detected from their training**. Replaces the Welcome → Class → Avatar → Created setup flow.

## Flow (mobile, `features/onboarding/`)

| # | Screen | Real data | Key animation |
|---|---|---|---|
| 1 | Welcome | static | Workout cards drop in, XP chips spark |
| 2 | Connect | Strava OAuth, Health Connect permission (Garmin shown as "soon" until its client id exists) | Round spinner around logo → green check + ring burst, workout count rolls up |
| 3 | Import | `POST /api/onboarding/import` summary | Rows slide in, XP orbs fly into the crystal ring |
| 4 | Level | Pending level-up receipt from the import | Bar fills level by level, number drops, HEAD START stamp + confetti |
| 5 | Reading your training | `GET /api/character/class-recommendation` | Sport bars race to their share, 40% line, verdict card |
| 6 | Class | same | Per state: clear / devoted / close (+hybrid merge) / balanced / insufficient picker |
| 7 | Avatar | Avatar catalog (starter + locked with progress) | Tiles pop, suggested avatar spins into preview |
| 8 | Map | Current region detail + banked km | Marker walks the trail to the first stop, zones light up |
| → | Home | `POST /api/character/setup`, then optional `setDestination` | Real shell + welcome toast |

"I'll log workouts by hand" on Connect skips to the class picker (insufficient state).

## Backend

### History import (Integrations + Activity)
- `POST /api/onboarding/import` — body `{ source: "strava" | "health", activities?: ExternalActivityDto[] }`. Allowed only while `IsSetupComplete == false`.
- Strava: pulls last 30 days server-side (existing `SyncRecentAsync`) in **history mode**. Health Connect: client sends the 30-day batch.
- History mode (`IActivityLogPort.ImportHistoricalActivityAsync`): stores the activity + external record (dedupe as today), applies stat gains, banks distance, **XP at 50%**, no quests / boss damage / guild raid / streak / season / notifications (no `ActivityLoggedEvent`).
- XP is awarded **once** for the whole batch → one level-up receipt. Response: count, km, minutes, total XP, level before/after, per-activity rows (type, date, km, minutes, xp) for the import feed.
- Step-derived walks (`...:steps:...`) are skipped for history import.

### Class detection (Character)
- `GET /api/character/class-recommendation` → `{ state, recommendedClassId, alternatives[], traitKey?, shares[] (group, classId, share), workoutCount, activeMinutes }`.
- Groups by active minutes over 30 days: Running/Cycling→Ranger, Gym→Warrior, Yoga→Mystic, Swimming→Tidecaller, Climbing→Cragborn, Hiking/Walking→Wayfarer.
- State order: `insufficient` (< 3 workouts) → `devoted` (one activity type ≥ 75%) → `multisport` (swim, bike, run each ≥ 15% → Stormrunner) → `hybrid` (top two groups ≥ 30%, ≤ 15 pts apart, known pair) → `balanced` (top < 40% → Sentinel) → `close` (≤ 10 pts, no hybrid) → `clear`.
- Hybrid pairs: Ranger+Warrior=Vanguard, Warrior+Mystic=Spellblade, Ranger+Mystic / Wayfarer+Mystic=Druid.

### Classes & traits
- Seed 7 new classes (Tidecaller, Cragborn, Wayfarer, Vanguard, Spellblade, Druid, Stormrunner) + `IsHybrid` column. Manual picker hides hybrids (shown as locked tile).
- **Apply class multipliers** to stat gains in `ActivityService` (currently unused).
- `Character.TraitKey` (e.g. `devoted:Running`), set by setup when the state is devoted and the player keeps the recommended class. +10% XP on that activity type while it stays ≥ 75% of the last 30 days.
- `CharacterSetupRequest` gains optional `ClassSource` (detected / changed / manual) — logged for analytics.

## Mobile structure
- `features/onboarding/onboarding_flow.dart` — controller (Riverpod) holding source, import summary, receipt, recommendation, chosen class, avatar; persists step via `SetupResumeService`.
- `features/onboarding/screens/*` — one file per screen.
- `features/onboarding/widgets/onboarding_fx.dart` — full-screen particle painter (burst, ring, confetti, embers, flying orbs), reused by all screens; honours `AppMotion` reduced motion.
- Strava deep link handled in the Connect screen (MainShell isn't mounted yet).
- Old setup screens removed from routing; `setupProgressDots` kept.
- Home header gets a small class chip.

## Verification
- Backend unit tests: recommendation states (all 7), history import (half XP, single receipt, no quest progress), class multipliers on stat gains, devoted trait bonus.
- Flutter widget tests: class screen per state, avatar default per class, connect → import happy path with fake services.
- Manual: `phone-test` run through Strava and hand-log paths.
