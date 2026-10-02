# Test Plan - Guided Feature Unlocks

Status: suggested coverage plan (2026-10-01).

Related implementation plan: [[Plan - Guided Unlocks]].

## Summary

Validate the complete current 13-feature unlock chain, including Titles & Ranks and Leaderboard.

A workout is not a separate unlock key. It is a gameplay action that can change several unlock facts at once, so tests must verify that one workout refreshes unlock state and queues every newly eligible ceremony in catalog order.

The current tour inventory contains 38 stops: Home has 2 stops and every other feature has 3.

## Unlock and tour matrix

| Order | Feature | Natural trigger | Required tour sequence |
|---:|---|---|---|
| 0 | Home | Complete onboarding | Hero -> Adventure Hub |
| 1 | Achievements | Log first workout | Continue -> Roads -> Claim All |
| 2 | Map | Log first distance | Map orb -> Journey card -> Dynamic journey action |
| 3 | Gear | Own first item | Slots -> Combat stats -> First item |
| 4 | Region Chests | Reach second zone | Current region -> Rewards -> Next region |
| 5 | Talents | Reach Level 3 | Crystals -> Grid -> Card Draw |
| 6 | Streak Shields | Reach three-day longest streak | Streak -> Shields -> Claim reward |
| 7 | Bosses | Spawn first personal boss | Boss card -> HP/damage -> Enter Battle |
| 8 | Titles & Ranks | Earn a title or advance above Novice | Rank -> Locked title -> Equip |
| 9 | Guild | Reach Level 5 | Member information -> Create -> Find |
| 10 | Leaderboard | Reach Level 6 | Scope tabs -> Your row/chest -> Metric board |
| 11 | Game Modes | Reach Level 10 | Burn Chain -> Locked Delve -> Start Burn Chain |
| 12 | Treasure Delve | Reach Level 15 | Delve banner -> Runs -> Enter vault |

## Automated coverage

### Backend

- Test every trigger immediately below and at its threshold.
- Test both Titles & Ranks conditions independently.
- Verify `UnlockFactsReadAdapter` derives activity, distance, items, zones, level, streak, boss, title and rank facts from persisted state.
- Assert the exact 13-key catalog order and API order.
- Verify new players receive ceremonies while eligible legacy accounts are silently backfilled.
- Verify seen/toured idempotency, 25 XP once, authorization, concurrent reads and unknown or locked-key rejection.

### Flutter contracts

- Assert the mobile catalog exactly matches the backend keys and order.
- Assert every tour has the expected ordered target IDs: 2 for Home and 3 for every other feature.
- Assert every target ID is mounted in the correct real screen state.
- Test locked, unlocked-unseen, seen-untoured and toured behavior for every feature.
- Test Show Me for all 13 features.
- Cover Later, Skip, Replay, interruption, missing targets and network recovery across representative route types.

### Workout orchestration

- Start immediately before multiple thresholds, submit one real workout and verify all affected providers refresh.
- Confirm level-up, boss-result, activity-result and other reward overlays finish before unlock ceremonies begin.
- Confirm multiple unlocks queue in catalog order without duplication.
- Reload and verify seen ceremonies do not replay while untoured features retain NEW.

### Focused flow assertions

- Map's first tap opens the journey card and its final dynamic action receives the tap.
- Bosses provide an active, fightable boss so `bossEnter` exists.
- Leaderboard provides available board data and a visible player row.
- Guild opens the no-guild discovery view containing all three targets.
- Modes distinguishes the Level 10 Modes unlock from the Level 15 nested Delve unlock.
- Opening the Modes tab with Modes toured and Delve fresh starts the Delve tour.

## Real end-to-end harness

- Add an isolated E2E PostgreSQL database and an authenticated endpoint available only in the `E2E` environment:
  - `POST /api/test/guided-unlocks/{key}/prepare`
  - Prepare exact pre-trigger state, mark earlier unlocks toured and leave the target locked.
  - Never directly mark the target eligible; the browser must perform its natural gameplay action.
- Use a controllable backend `TimeProvider` for the three-day streak test. Advance virtual days between real UI workout submissions.
- Drive all 13 flows through the real API with Flutter `integration_test`.
- Use Playwright for black-box smoke coverage:
  - Registration -> onboarding -> Home tour.
  - Workout -> Achievements and Map unlock queue.
  - Level 5 -> Guild and Level 6 -> Leaderboard.
  - Boss spawn -> Boss ceremony and battle tour.
  - Level 10 -> Modes and Level 15 -> Delve.
- Use a unique player for each case and run clock-dependent scenarios serially.

## Visual, Android and CI validation

- Capture deterministic goldens for:
  - 12 non-Home ceremonies.
  - All 38 current tour stops.
  - Every locked destination and NEW placement.
  - Every feature's explored card.
- Include compact and tall-phone layout checks for spotlight placement, scrolling, safe areas, overflow and tap-through.
- Manually smoke-test Home, Map, Bosses, Guild, Leaderboard, Modes and Delve on Android, recording device details and screenshots or video.
- Add GitHub Actions coverage:
  - Pull requests: backend tests, Flutter unit/widget tests, all goldens and representative integration/Playwright smoke flows.
  - Nightly or manual: all 13 natural-action E2E flows and branch/error scenarios.
  - Upload browser traces, screenshots, backend logs and golden diffs on failure.

## Acceptance criteria

- All 13 triggers unlock only at the intended gameplay threshold.
- Every current tour step points to a visible and correct widget.
- Workout-driven refresh discovers all newly eligible features.
- Ceremony order follows the backend catalog.
- Show Me opens the correct route; Later runs the same tour on first visit.
- Final spotlight taps execute the real action.
- Leaderboard unlocks at Level 6 after Guild at Level 5.
- Modes and Delve remain separate unlocks with correct nested-tab behavior.
- Completion persists, removes NEW and awards exactly 25 XP once.
- Test-only APIs are unavailable outside E2E.
- No unexplained golden differences, missing targets, overflow or asset warnings remain.

## Assumptions

- Newly added feature-unlock coverage such as Leaderboard belongs to the existing chain; Workout is not a fourteenth unlock.
- The app implementation is the source of truth: Home has two stops and Map's final stop targets the dynamic journey action.
- Full Show Me coverage applies to every feature; secondary branches use representative route categories.

