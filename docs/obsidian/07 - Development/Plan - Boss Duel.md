# Plan - Boss Duel (option A)

Status: implemented 2026-10-01 (backend + mobile), not yet committed; on-device check pending.


## Context
Design source: the **A · Duel card** artboards on the Boss Duel HUD canvas
(https://claude.ai/artifact/58ef7574wL7MyuYFFgf3xX).
- **Home:** there is no boss card. The raised Map button carries the fight:
  - an inner red ring for boss HP and an outer green ring for your HP,
  - the attack and counterattack effects,
  - the Finisher sequence (charge-up → impact → shatter → VICTORY → Boss slain),
  - the KO sequence (crack + K.O. stamp → recovering countdown).
- **Bosses page:** the duel card (boss HP + your HP) plus a "Since your last visit" list. The list replays each exchange once.

The backend already simulates every exchange. `BossCombatTurn` stores damage dealt, boss HP after, damage taken, player HP after, KO and skip reason, and `UserBossState` holds current player HP and recovery. The app is missing four things:
1. **Your HP outside the battle screen.**
2. **A counterattack animation.**
3. **A memory of what the player has seen that survives a restart.** `BossHitMemory` is an in-memory map, so a cold start shows the new HP with no animation.
4. **A celebration for bosses killed by a pull-import.** Only the manual log fires `BossDefeatedNotifier`.

Goal: the player feels every exchange once, at the moment they first come back to the game after it happened.

## When the animation plays (triggers)
"Unseen turns" are combat turns newer than the player's saved cursor for that boss. They play once, wherever the player sees the boss first.

| Trigger | Where it plays | When exactly |
|---|---|---|
| **Pull-to-import** on Home (`runPullImportFlow`) | Home / Map button | After `playImportCelebration` finishes, so the workout icons fly into the hero first, then the boss exchange runs on the Map button. |
| **Manual log** (`log_activity_screen` → back to shell) | Home / Map button | When the shell is visible again. It replaces today's direct `BossDefeatedNotifier` call so the Finisher runs the full sequence. |
| **App open / resume** (turns that landed while away, e.g. from the quiet health sync or a different device) | Home / Map button | On the first frame Home is visible and nothing else is on screen. |
| **Opening the Bosses page / battle screen** with unseen turns | Duel card | About 400 ms after the page settles, the duel card plays from last-seen to current and fills the list one row at a time. It then marks the turns seen, so Home won't replay them. |
| **Map button tapped mid-replay** | n/a | The replay jumps to the final state (no queue left behind). |

**Order with other overlays** (one at a time, via the shell's gate):
1. Import celebration.
2. Boss exchange.
3. Boss slain takeover (if killed).
4. Level-up screen.
5. Unlock ceremonies.

The exchange waits while a sheet, route or level-up is open (same rule as `_canShowUnlock`), and the unlock and level-up queues wait for it.

**Timing per turn on Home, about 1.6 s.** For 4 or more turns, play the last 3, prefixed by one combined "×N" summary hit.
- **0 ms:** toast "Evening run synced · 1 attack". The red ring drains, with a pale trail following ~350 ms later.
- **~750 ms:** counterattack:
  - red edge vignette,
  - screen shake (on Home: the shell body),
  - haptic,
  - the green ring drains, with a "−45" pill floating up from the button.
- **Finisher** (no counterattack):
  - 0.6 s charge-up (dim, spinning gold ring, sparks pulled in),
  - impact flash and shake,
  - shards, 3 shockwaves and rays, the button turns gold "Victory",
  - VICTORY banner for ~1.7 s,
  - then the Boss slain takeover with count-up XP and coins and a Claim button.
- **KO:**
  - red flash, crack overlay, slammed K.O. stamp (~2 s),
  - then the button goes grey with a live `h:mm:ss` recovery countdown, a spinning recovery ring and a one-time popover.
- **Reduced motion** (`AppMotion.allowsDecorativeMotion` false): skip straight to the final rings, and still show the takeover and popover (static).

## Backend (small)
- `BossDamageHistoryItemDto` (`LifeLevel.Modules.Adventure.Encounters/Application/DTOs/EncounterDtos.cs`): add `TurnId`, `BossHpAfter`, `BossMaxHp` (snapshot), `DamageBlocked` (= `BossCounterattackRaw − DamageTaken`) and `BossDefeated`. Fill them in the `BossCombatTurn` projection in `BossService.GetDamageHistoryAsync`. The pre-V2 fallback leaves them at 0.
- Boss list (`GET /boss`): confirm that a boss defeated in the last 24 h stays in the list with `isDefeated`, so the replay can still find it after the kill. If it doesn't, add `recentlyDefeated` to the query.
- Tests in `backend/tests/LifeLevel.Api.Tests/`: history returns the new fields, and the blocked value is right.

## Mobile

### 1. Remembering what was seen
New file: `features/boss/replay/boss_seen_store.dart`.
- Uses `SharedPreferences`, keyed per user and boss: `{lastTurnAt, bossHp, youHp}`.
- Replaces `BossHitMemory`'s static map. Keep the `seen` / `markSeen` API so `home_portal_card.dart`, `encounter_blocker_sheet.dart` and `boss_battle_screen.dart` keep working.
- First run for a boss with no record: mark it seen silently. Nothing replays from history.

### 2. Building the replay
New file: `features/boss/replay/boss_replay_controller.dart`, a Riverpod notifier.
- `checkForUnseen()`:
  - reads `bossListProvider` (the active boss plus bosses killed in the last 24 h),
  - fetches `bossDamageHistoryProvider(id)`,
  - keeps turns newer than the cursor,
  - builds a `BossReplay(turns, startBossHp, startYouHp, maxes, finished, ko, recoveryEndsAt)`.
- Exposes `pending`, `markSeen()` and `skipToEnd()`.
- `checkForUnseen()` is called from the three Home triggers:
  - the end of `runPullImportFlow` (`features/sync/pull_import_flow.dart`),
  - the shell's `ItemObtained` / `LevelUp` / resume hooks and the manual-log return in `core/shell/main_shell.dart`,
  - `didChangeAppLifecycleState` resumed (after `_invalidateAllProviders`).
- `log_activity_screen.dart`: drop the direct `BossDefeatedNotifier.notify` loop; the replay covers kills. Keep the notifier for guild/other callers if any.

### 3. Map button: two rings and replay effects
- `features/map/journey/journey_state.dart`: give `JourneyOrbState` optional `secondaryProgress` and `secondaryColor` for your HP, set in the `bossRaid` branch from `BossListItem.currentPlayerHp / playerMaxHp`. Add states `bossVictory` (gold, label "Victory") and `bossRecovering` (grey, countdown label from `recoveryEndsAt`).
- `core/shell/widgets/map_orb_button.dart`:
  - Paint the outer green ring with a second `JourneyRingPainter` at inset −9, plus a trail layer (a delayed tween) on both rings.
  - Add an `OrbReplayLayer` overlay that plays charge, shards, shockwaves and rays.
  - Reuse `RewardFx.ring`, `RewardFx.burst`, `RewardFx.floatText` and `ShellAnchors.mapOrb`.
- New file: `features/boss/replay/home_boss_replay.dart`. It runs the sequence from the controller:
  - the toast via the existing `AppToast` / `RewardMoment.banner`,
  - the vignette and shake as an `OverlayEntry` on the root overlay,
  - the VICTORY banner and K.O. stamp with cracks as `OverlayEntry`s,
  - haptics via `AppMotion.haptic`; add `AppHaptic.medium` and `AppHaptic.heavy` to the enum in `core/motion/app_motion.dart`.
- **Boss slain takeover:** extend `core/widgets/boss_defeated_overlay.dart` / `RewardMoment` takeover with:
  - spinning rays and a crack across the portrait,
  - a count-up for XP and coins (from the existing `BossDefeatedInfo.rewardXp` plus coins if the backend sends them),
  - a gold Claim button with a shine sweep.
- **KO popover:** a one-time tooltip above the button, "Attacks resume in 5h 59m 57s. Workouts still earn XP and coins". The countdown label ticks every second only while Home is visible.

### 4. Bosses page duel card
- `features/boss/widgets/boss_active_card.dart`:
  - Add the "You" row: avatar, green bar (`currentPlayerHp / playerMaxHp`, amber below 50%, red below 25%, grey while recovering) and the "Recovering · …" text.
  - Show the "Boss ATK · Defense blocks n%" line from `counterattackDamage` and `playerMitigation`.
- `features/boss/widgets/boss_hit_fx.dart`: extend `BossHitScope` to drive two bars from a turn list:
  - the boss hit uses the existing `BossSlash`, shake and gold number,
  - then the counter: claw marks, a red "−45", a blue "12 blocked" chip and a recoil on the avatar,
  - a ×N combo badge, and DEFEATED / KO stamps.
- `features/boss/screens/boss_screen.dart`: a "Since your last visit" section under the active card. Rows fade in as each turn plays: activity icon, "−320" dealt, "−45 HP" taken. Mark the turns seen at the end.

### 5. Shell gate
`core/shell/main_shell.dart`:
- Add `_bossReplayRunning`.
- `_canShowUnlock()` and `_checkPendingLevelUps()` wait while it's true.
- The replay itself waits for `_canShowUnlock()`-style conditions: Home tab, no overlay, no sheet.

## Delivery order
0. Save this plan as `docs/obsidian/07 - Development/Plan - Boss Duel.md`.
1. Backend DTO fields and tests.
2. Seen store, replay controller and triggers. Verify that the cursor survives a restart.
3. Map button double ring with drain, trail, counterattack vignette and shake.
4. Finisher and KO sequences, plus the takeover upgrade.
5. Bosses page duel card and list.
6. Shell gate ordering and reduced motion.

## Verification
- **Backend:** `dotnet test --filter "FullyQualifiedName~Boss"`.
- **Mobile tests:**
  - `boss_replay_controller_test.dart`: unseen turns after the cursor, the first-run silent mark, ≥4 turns collapsing into a combo.
  - `boss_seen_store_test.dart`: persistence across instances.
  - Golden or widget tests for the double ring and the duel card rows.
- **On device** (`phone-test` skill), with a seeded active boss:
  - Log a workout → return to Home: single exchange on the Map button, both rings drop.
  - Pull-to-import 3 workouts: import celebration → ×3 combo → toast.
  - Import a killing workout: charge → VICTORY → Boss slain takeover → then the level-up, if any.
  - Force KO (low player HP): K.O. stamp → grey countdown button → popover.
  - Kill the app after the import without looking, reopen: the replay plays once on Home, never twice.
  - Open the Bosses page first after a sync: the duel card plays and Home stays quiet afterwards.
  - Turn on reduced motion: final states only, no shake.
- `flutter analyze`, `flutter test`, then `graphify update .`.

## What shipped (2026-10-01)
- **Backend:** `BossDamageHistoryItemDto` gained `TurnId`, `BossHpAfter`, `BossMaxHp`, `DamageBlocked` and `BossDefeated`. Test: `GetDamageHistory_PersistedTurns_CarryReplayFields`.
- **Mobile, `features/boss/replay/`:**
  - `boss_seen_store.dart`: persistent "seen" HP per boss. It backs `BossHitMemory`, is loaded in `main()` and cleared on logout.
  - `boss_replay.dart`: `BossReplayFinder` (unseen turns after the cursor; fresh installs replay only the last 15 min) and `collapseTurns` (≥4 → ×N plus the last 3).
  - `home_boss_replay.dart`: Map-button sequence (hit, counter, charge → VICTORY, K.O. + recovery popover), plus `ShellShake` and `requestBossReplay()`.
  - `boss_slain_takeover.dart`: rays, portrait crack, confetti, XP count-up, gold Claim button.
- **Map button:**
  - The rings draw the *seen* values, with an outer player-HP ring and a pale trail on drops.
  - New states: gold "Victory" while finishing, grey countdown while recovering.
  - An unwatched kill keeps the fight on the button for up to 24 h.
- **Bosses page:** the active card shows the player's HP row and the Boss ATK / Defense line. On open it replays unseen exchanges and lists them under "Since your last visit".
- **Triggers:**
  - `requestBossReplay()` after a manual log (replacing the direct `BossDefeatedNotifier` call) and after a pull-import.
  - Cold start and resume.
  - The shell holds level-ups and unlock ceremonies until the replay ends.
- **Tests:** `test/features/boss/boss_replay_test.dart`.

## Change 2026-10-01: split ring
The outer green ring made the Map button too big. Option 1 from the canvas row "Map button · 5 ways to show your HP" replaces it:
- One ring in today's footprint. Your HP fills the left half from the bottom up, the foe's HP the right half, and both leave a pale trail on drops.
- `DuelRingPainter` / `_TrailedDuelRing` in `map_orb_button.dart`, used whenever `JourneyOrbState.secondaryProgress` is set.
- It applies to boss raids and to trail **blockers** (mobs). A blocker reads the player's HP from its linked boss (`BlockerEncounterData.bossId` → `BossListItem`). Test: "a blocker fight splits the ring with the player HP".

## Change 2026-10-01: recap after the exchange
The top toast pulled the eye away from the damage on the Map button. It is replaced by option 3 from the canvas row "Sync notice · 5 ways that don't steal the hit":
- Nothing appears during the exchange.
- Afterwards, `_RecapPill` (`home_boss_replay.dart`) rises just above the Map button:
  - Normal fight: "Evening run hit Forest Warden · 320 dealt · 45 taken · 880 HP left". Several workouts show "×N" on the icon.
  - Knock-out: red "… knocked you out", with a live "attacks resume in 5h 59m 57s" countdown. This replaces the separate recovery popover.
  - Kill: no pill; the Boss slain screen is the recap.
- Tapping it closes it. It closes on its own after 3.6 s (6.5 s for a knock-out).
- **Every workout path ends in the recap.** These all call `requestBossReplay`: pull-to-sync on Home, the journey card's Sync button, the pending pill, a manual log, Health "Sync now" in Integrations, and app resume.
- **Import summary in the recap.** After an import, the summary ("+120 XP · STR +2 · 6.2 km on the map") moves into the recap as a third line, so the top "Imported N workouts" toast no longer competes with the exchange. With no boss exchange to play, `orElse` shows the usual toast instead.

## Change 2026-10-01: route row on the boss card
During a boss raid the journey card only offered Sync and Fight →, with no way back to the region. It now ends with a journey row (option 2 from the canvas row "Boss fight · 5 ways back to the region map"):
- **Content:** the region name, "Dawn Camp → Whispering Fork · 1.4 km left" (or "At Dawn Camp"), and **Map ›**.
- **Map ›** opens that region and zone through `WorldMapNotifier`.
- **Code:** `_BossJourney` / `_BossJourneyRow` in `home_portal_card.dart`, shown through the new `_HeroShell.footer`.
- **Test:** "boss raid card keeps the route one tap away".

