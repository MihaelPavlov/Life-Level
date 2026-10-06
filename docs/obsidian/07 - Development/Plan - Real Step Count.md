# Plan — Real step count in the Home top bar

## Context
The Home top bar shows `totalSteps` from `GET` activity summary (`ActivityService.GetSummaryAsync`), which sums `Activity.Steps`. Every activity's `Steps` is **estimated** by `CalculateSteps` (`ActivityService.cs:616`) as `distanceKm × 1250` for Running/Hiking/Walking/Cycling. Problems:
- Cycling produces "steps" (40 km ride = 50,000 steps).
- Runs are double-counted: the phone's daily step total (imported as a `:steps:` Walking activity) already includes the run's steps, then the run's distance × 1250 is added again.
- Phone steps are converted to km and back to steps, so the real number never reaches the DB.

User picked option 1 (no cycling steps) + option 3 (store the real step count from Health; stop estimating for workouts). Option 1 is covered by option 3: once estimation is removed, cycling (and every workout) contributes 0 steps.

**Rule after this change:** `Activity.Steps` = the real count the phone sent; everything else = 0. Only the Health daily-steps walk (`<prefix>:steps:<date>`) carries steps. Metric stays lifetime total (the "today only" option was not chosen).

## Changes

### Mobile
1. `mobile/lib/features/integrations/models/integration_models.dart` — add `final int? steps;` to `ExternalActivityDto` (ctor + `toJson` `'steps': steps`).
2. `mobile/lib/features/integrations/services/health_sync_service.dart` `_buildDailyStepActivities` — pass `steps: totalSteps` in the `ExternalActivityDto` it builds. Distance/duration estimates stay (they drive XP and map movement).

### Backend
3. `Integrations/Application/DTOs/IntegrationDtos.cs` — add `public int? Steps { get; set; }` to `ExternalActivityDto`.
4. `Integrations/Domain/Entities/PendingActivity.cs` — add `public int? Steps { get; set; }`; `PendingActivityService.Apply` copies `dto.Steps`; import path passes `row.Steps` on.
5. `SharedKernel/Ports/IActivityLogPort.cs` — add an optional `int? steps = null` parameter (before `ct`) to `LogExternalActivityAsync` and `ImportHistoricalActivityAsync`.
6. Callers pass steps through:
   - `HealthSyncService.cs:122` (live sync) → `dto.Steps`
   - `HealthSyncService.cs:190` (history import) → `dto.Steps` (note: this path currently skips `:steps:` rows; leave that as-is)
   - `PendingActivityService` import call → `row.Steps`
   - `ReprocessStuckAsync` has no DTO → leave default null.
7. `Activity/Application/UseCases/ActivityService.cs`
   - `LogActivityAsync` (manual log): `Steps = 0`.
   - `LogExternalActivityAsync` / `ImportHistoricalActivityAsync`: `Steps = Math.Max(0, steps ?? 0)`.
   - Delete `CalculateSteps`.
8. EF migration (Integrations module context / `AppDbContext`, whichever owns `PendingActivities`) adding nullable `Steps` to `PendingActivities`, plus a data step on `Activities`:
   `UPDATE "Activities" SET "Steps" = 0 WHERE "ExternalId" IS NULL OR "ExternalId" NOT LIKE '%:steps:%';`
   Existing `:steps:` walks keep their value (distance×1250 reproduces the original phone count closely), so current users' totals become correct without a re-sync.

### Tests
9. `backend/tests/LifeLevel.Api.Tests`:
   - Pending import of a `:steps:` DTO with `Steps = 8421` → resulting Activity.Steps == 8421.
   - Running/Cycling import with distance → Steps == 0.
   - Extend the existing `Stage_SkipsTodaysStepWalk_ButQueuesFinishedDays` helper with `Steps`.

## Out of scope
- Showing today's steps instead of lifetime (option 2).
- Real step counts on Health workouts (not available from Strava; Health workouts already fall inside the daily total).

## Verification
- `dotnet build` + `dotnet test backend/tests/LifeLevel.Api.Tests`.
- Apply migration locally; check `SELECT SUM("Steps") ... ` for test1@abv.bg drops to only the step-walk totals.
- `flutter analyze` on touched files.
- Run the app (Chrome / device) logged in as test1@abv.bg: Home top bar shows the summed real step count; logging a manual run or a cycling import does not change it.
- Run `graphify update .` after code changes.
