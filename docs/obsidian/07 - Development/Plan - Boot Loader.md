# Plan - Boot Loader (design F) before Home

## Context
After login, or after finishing registration setup, the app jumps straight into `MainShell`. Home's data is still loading, so the player briefly sees half-built state: the Map button showing **Retry** (`journeyOrbStateProvider` → `JourneyKind.error` when `worldProgressProvider` errors or isn't ready), zero coins and gems, missing steps, and tabs flipping as `unlocksProvider` resolves. We'll show the design-F loader (Life Level logo in a progress ring, plus a 4-row checklist and a slow-connection retry) on top of Home until the data Home actually renders has really loaded, then fade it away.

Shown **only after login and after setup completes**, not on a cold start that's already signed in (`main.dart` AuthGate stays as is).

## Approach: an overlay inside MainShell (not a separate route)
Home builds underneath straight away, so its own widgets start every fetch. The loader watches **the same providers** and only lifts when they've resolved. This avoids `autoDispose` providers (`worldProgressProvider`, `currentRegionDetailProvider`) being thrown away between a separate loading route and Home, and it guarantees the check is real, because it's the data Home is actually showing.

### Readiness groups (the 4 checklist rows)
| Row | Providers that must have data (`hasValue`) |
|---|---|
| Hero profile | `characterProfileProvider` (level, avatar, coins, gems via `talents`), `activitySummaryProvider` (steps chip) |
| Map & journey | `worldProgressProvider`, `currentRegionDetailProvider`, `bossListProvider` (inputs of `journeyOrbStateProvider`) |
| Quests & streak | `streakProvider`, `dailyQuestsProvider`, `seasonProvider` |
| Rewards & unlocks | `unlocksProvider` (locked tabs / Mode / Gear), `adventureHubSignalsProvider` |

A row is **done** when all its providers have a value, **failed** when any has an error, otherwise **loading**.

### Behaviour
- **Minimum 800 ms on screen** (no flash), then when all 4 rows are done: ring turns green, "Ready, hero", fade out (~350 ms).
- **After 8 s** with something still loading, show "Taking longer than usual · Try again". Try again invalidates the providers of the rows that aren't done.
- **A failed row** shows a red mark and the same Try again, scoped to that row.
- **After 20 s**, also offer "Continue anyway", so a flaky endpoint can't trap the player.
- **Taps are blocked** while the loader is up (`AbsorbPointer`).
- **Reduced motion:** no ring animation or sweep; just the checklist and a crossfade.

### Hold other moments until the loader is gone
Add a global `bootLoaderShowing` flag, following the `unlockCeremonyShowing` pattern in `features/unlocks/tour/unlock_tour_runner.dart`, and check it in:
- `MainShell._canShowUnlock()`, `_canPlayBossReplay()` and `_checkPendingLevelUps()` (main_shell.dart, around lines 630–945), so they wait and retry like they do for tours.
- `TourOnFirstVisit._maybeRun()` (unlock_tour_runner.dart:87).
- The onboarding welcome toast (`PendingWelcome.take()`, main_shell.dart ~352): show it after the loader closes.

## Files
**New**
- `mobile/lib/core/shell/boot/boot_readiness.dart`
  - `BootStep` enum, `BootStepState` (loading / done / failed).
  - `bootReadinessProvider` (`Provider.autoDispose`) folding the AsyncValues above into the 4 rows.
  - `retryBootStep(ref, step)`, which invalidates that row's providers.
- `mobile/lib/core/shell/boot/boot_loader.dart`: the `BootLoaderOverlay` widget, design F.
  - Logo with the progress ring (ring fraction = rows done / 4), light sweep and pulse.
  - The 4 rows with spinner, check or error marks.
  - "Preparing your world" → "Ready, hero".
  - The slow and failed states, timers, and the exit fade.
  - Calls `onFinished`.

**Edited**
- `mobile/lib/core/shell/main_shell.dart`:
  - New `showBootLoader` constructor flag and `_booting` state.
  - The overlay is the top child of the existing build `Stack` (~line 1214).
  - `bootLoaderShowing` is set while it's up.
  - The checks above gate on it, and the welcome toast is deferred.
- `mobile/lib/features/auth/auth_flow.dart:36`: `MainShell(initialRingIds: …, showBootLoader: true)`.
- `mobile/lib/features/onboarding/screens/map_step.dart` (the `pushAndRemoveUntil` in `_enter`): pass `showBootLoader: true`. Its exit already fades to `#040810`, which matches the loader background.
- `mobile/lib/features/unlocks/tour/unlock_tour_runner.dart`: add the `bootLoaderShowing` check.

**Reuse**
- `AppIcons` logo asset.
- `AppColors`.
- `onboardingMotion` / `AppMotion.allowsDecorativeMotion` for reduced motion.
- `invalidateUserScopedProvidersFromContainer` stays as is. Auth already clears caches before pushing, so the loader always waits on fresh data for the new account.

**Docs:** save this plan as `docs/obsidian/07 - Development/Plan - Boot Loader.md` and update `CLAUDE.md`'s `core/shell/` table with the two new files.

## Verification
1. `flutter analyze` on the touched folders.
2. **Unit test** `test/core/shell/boot_readiness_test.dart`: with overridden providers, check that rows go loading → done, that any error marks the row failed, and that the overall state is ready only when all 4 rows are done.
3. **Widget test:** pump `BootLoaderOverlay` with fake readiness and check:
   - the 800 ms minimum;
   - the slow message after 8 s (`tester.pump(Duration(seconds: 8))`);
   - Try again calls retry;
   - `onFinished` fires after ready.
4. **Manual on web (localhost:5000)** and the Redmi:
   - Log in and confirm the loader shows. When it lifts, coins, gems, steps, the Map button (no Retry), locked tabs and the streak are all populated.
   - Finish setup through Enter the World and confirm the loader shows after the exit fade.
   - Throttle the network in DevTools and confirm the slow message and Try again appear.
   - Kill the backend mid-load and confirm the failed row, Try again and "Continue anyway".
   - Cold start while signed in: no loader.
   - Confirm level-up, unlock tour and the welcome toast only appear after the loader closes.
