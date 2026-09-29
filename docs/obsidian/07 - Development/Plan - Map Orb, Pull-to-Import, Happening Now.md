# Plan - Map Orb, Pull-to-Import, Happening Now

Status: implemented 2026-09-29 (backend + mobile, tests green; migration `PendingActivities` not yet applied to the database).

Design sources (artifacts):
- Pull-to-import flow: https://claude.ai/artifact/Q9W1PQ4mmZeMuybzQtvSQY
- Map orb states + tab bar: https://claude.ai/artifact/MtoXf6boox6nuxJAZfw8L4
- Home with Happening now (chips + focus): https://claude.ai/artifact/21RRtEHYRR6u6e65V3LP9j

## Goals
1. Workouts from Strava / Garmin webhooks and Health Connect / Apple Health land in a **pending queue** instead of awarding XP immediately. The player pulls Home down to review and import them.
2. The bottom bar becomes **Home · Gear · [Map orb] · Profile · Menu**. The radial ring, boss FAB and customize sheet go away.
3. The Home map card moves into the **Map orb**: the orb shows the journey state (ring, icon, colour, label, alert dot) and tapping it opens the same journey card above it.
4. Home gets a **Happening now** section (chips + focus card) for live, timed things: guild raid, active boss fight, season.

## Backend (Integrations module)
- New entity `PendingActivity` (UserId, Provider, ExternalId, ActivityType, DurationMinutes, DistanceKm, Calories, HeartRateAvg, PerformedAt, CreatedAt, Status, DuplicateOfId, ImportedActivityId, XpAwarded). Unique (UserId, Provider, ExternalId). Status: Pending, Imported, Duplicate.
- `PendingActivityService`
  - `EnqueueAsync` — skip if already imported (ExternalActivityRecord.WasImported); upsert a Pending row; mark Duplicate when another workout from a different provider started within 10 minutes with a similar duration.
  - `StageAsync` — phone uploads Health Connect / Apple Health workouts it read locally; each goes through `EnqueueAsync`.
  - `ListAsync` — pending + recent duplicates, each with an XP / stat preview.
  - `ImportAsync(ids)` — imports each selected pending workout through the existing `HealthSyncService` path (same dedupe), returns XP per workout and totals.
- Strava and Garmin webhooks call `EnqueueAsync` (one provider fetch per activity, as before) and send one push per batch (`workouts-pending`, deeplink `lifelevel://home`).
- The pull never calls Strava or Garmin. Manual "Sync" on the Integrations screen keeps importing directly (explicit action).
- Shared kernel port `IActivityGainPreviewPort` so Integrations can preview XP/stats without depending on the Activity module.
- Endpoints: `GET /api/integrations/pending`, `POST /api/integrations/pending/stage`, `POST /api/integrations/pending/import`.
- Migration `PendingActivities`. Tests for enqueue, duplicate, stage, import, already-imported skip.

## Mobile
- `features/sync/`: pending models + service + `pendingWorkoutsProvider`; `PullToImport` wrapper for Home (rune that fills, release to check, spinning while checking); pending pill at the top; review sheet (select/deselect, duplicate row, totals, Import / Later); import animation (icons fly to hero, XP float, avatar ring, map orb fill, recap).
- Foreground Health Connect sync on resume now **stages** workouts instead of importing them. Daily step walks are staged only for finished days.
- `core/shell/`: new `ShellTabBar` + `MapOrbButton` + `JourneySheet` (hosts `HomePortalCard`) + `MenuSheet` (grid of features). Remove radial ring / boss FAB / customize usage from the shell.
- `features/map/journey/journey_state.dart`: shared helpers moved out of `home_portal_card.dart` (pick zone, next zone, current edge encounter) + `journeyOrbStateProvider` that maps every portal case to an orb look.
- Home: remove the portal card; add `HomeHappeningNow`; keep "Log workout" only when no integration is connected (temporarily always shown for testing via `kAlwaysShowLogWorkout` in `home_screen.dart`).
- Tutorial keys: `mapTab` → map orb, `bossFab` → Menu tab.

## Verification
- `dotnet build`, `dotnet test`.
- `flutter analyze`, `flutter test` (new widget tests: orb states, review sheet, happening now, tab bar).
- Compare against the three artifacts (layout, copy, states, animations).
