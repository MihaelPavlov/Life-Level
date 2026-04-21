# Life-Level Task Board

> Source of truth for active work. Human-editable markdown, parseable by the `/work-next-ticket` slash command. Replaces the static `design-mockup/project-board.html` for actual execution.

## Format

Each ticket is an `### LL-NNN — Title` heading with a consistent metadata block:

```markdown
### LL-042 — Short imperative title
- **Layer**: backend | mobile | game-engine  (comma-separated if multi)
- **Agent**: backend | flutter-ui | game-engine  (comma-separated → dispatched in parallel)
- **Priority**: high | medium | low
- **Phase**: P7 | P8 | ...
- **Acceptance**:
  - [ ] Binary criterion 1
  - [ ] Binary criterion 2
- **Notes**: free-form context, vault links, blockers
```

**Layer** is the code surface the ticket touches (e.g. `backend, mobile` for cross-cutting work). **Agent** is the subagent(s) who implement it — `backend` → `.claude/agents/backend.md`, `mobile` → `flutter-ui.md`, `game-engine` → `game-engine.md`. Multi-value Agent means parallel dispatch: the manager spawns all listed agents in a single message.

**Columns** (each `## ` heading = a Kanban column):

| Column | Purpose |
|---|---|
| 🟡 In Progress | Actively being worked this week |
| 🛑 Blocked / Discussion | Started, paused waiting for user decision, external dep, or open question. Agent should **not** auto-pick these. |
| 🐛 Bugs | Known defects with reproduction steps. Agent can pick these when In Progress is empty. |
| 📋 Backlog | Not started. Pull into In Progress when ready. |
| ✅ Completed | Finished tickets with checked acceptance + `Implemented:` line + commit SHA |

**Status lives in the column** — move the ticket between sections (edit the `##` heading it's under). The agent never changes column without approval.

---

## 🟡 In Progress

### LL-001 — Wire XP Storm ×2 multiplier into activity XP formula
- **Layer**: backend
- **Agent**: backend
- **Priority**: medium
- **Phase**: P7
- **Acceptance**:
  - [ ] `ActivityService.LogActivityAsync` detects active XP Storm window at log time
  - [ ] Multiplier applied after gear bonus, before final `XpGained`
  - [ ] Unit test covers storm-on / storm-off / both for all 8 activity types
  - [ ] `LogActivityResult` exposes whether storm was applied (for mobile UI)
- **Notes**: Currently Day 7 login reward sets `IsXpStorm = true` flag but no multiplier is applied. See `docs/obsidian/02 - Game Design/XP and Leveling.md` and `docs/obsidian/03 - Backend/Modules/Activity.md`.

---

## 🛑 Blocked / Discussion

> Tickets parked here are started but paused — waiting on a user decision, an external dependency, or an unresolved design question. The manager agent **will not auto-pick** from this column; use `/work-next-ticket LL-NNN` to force a specific one.

*(No blocked tickets right now. Move a ticket here when it needs input before coding can continue, and add a `- **Blocker**: <what's needed>` line to its body.)*

---

## 🐛 Bugs

### LL-029 — World-map character doesn't move & zone progress bar stuck at 0
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui
- **Priority**: high
- **Phase**: bug
- **Reproduction**:
  1. Set a destination zone on the world map
  2. Log an activity with distance > 0
  3. Re-open world map → character still on source zone
  4. Tap destination zone → bottom-sheet progress bar reads 0%
- **Acceptance**:
  - [x] `ActivityService.LogActivityAsync` invokes `IWorldZoneDistancePort.AddDistanceAsync` when `DistanceKm > 0`
  - [x] `WorldZoneService.AddDistanceAsync` silently returns (no throw) when no destination is set
  - [x] `WorldZoneModule.AddWorldZoneModule` registers `IWorldZoneDistancePort`
  - [x] `log_activity_screen.dart` calls `WorldZoneRefreshNotifier.notify()` after successful log
  - [x] Tests cover both no-destination and with-destination paths
  - [ ] Manual verification: character moves along edge and detail sheet progress bar updates in real time
- **Notes**: Root cause — `Activity → WorldZone` port never existed. `IMapDistancePort` only advanced the dungeon map, so `UserWorldProgress.DistanceTraveledOnEdge` stayed at 0, which fed directly into both the map character position (`distanceTraveledOnEdge / edge.distanceKm`) and the zone detail progress bar. Fix adds `IWorldZoneDistancePort` in SharedKernel, implemented by `WorldZoneService`, wired from `ActivityService`, and fires `WorldZoneRefreshNotifier.notify()` on mobile log so an open map reloads immediately. See plan: `.claude/plans/mutable-pondering-blum.md`. **Follow-up patch (same ticket):** manual spot-check surfaced a visual-only bug — the destination zone was mapped to `ZoneStatus.active`, which drives the blue pulsing glow + dark-blue fill, while the source zone dimmed to `completed` while traveling. This made it look like the character instantly "flew" to the destination on tap. Fix in `world_map_models.dart`: removed the `isDestination → active` and `isCurrentZone && isTraveling → completed` branches so the current zone stays blue-active and the destination is marked only by the orange pulsing ring (already driven by `isDestination`). Dropped the now-unused `isTraveling` parameter.
- **Follow-up**: Mirror `UserMapProgress.PendingDistanceKm` reserve-km banking onto `UserWorldProgress` so distance logged before setting a destination is not lost (needs entity field + EF migration). Out of scope for this ticket.
- **Implemented**: commit pending — backend: `IWorldZoneDistancePort` added to SharedKernel, implemented by `WorldZoneService` (silent no-op when no destination), wired into `ActivityService.LogActivityAsync` and `LogActivityFromExternalAsync` when `DistanceKm > 0`; mobile: `log_activity_screen.dart` fires `WorldZoneRefreshNotifier.notify()` post-log; `world_map_models.dart` status mapping fixed so the blue-active glow stays on the source zone while traveling. Files: `ICharacterXpPort.cs`, `ActivityDtos.cs`, `ActivityService.cs`, `WorldZoneService.cs`, `WorldZoneModule.cs`, `log_activity_screen.dart`, `world_map_models.dart`, `world_map_screen.dart`.
- **Implemented (second pass — progress bar & reset bug)**: commit pending — the earlier `world_map_models.dart` follow-up removed the `isDestination → ZoneStatus.active` mapping, which made the `zone.status == ZoneStatus.active && zone.isDestination` branch in `world_map_detail_sheet.dart:257` unreachable (the destination zone is `available + isDestination` during travel). Net effect: tapping the destination tile never rendered the progress bar; it fell through to the generic "Set as Destination →" button, and tapping that called `SetDestinationAsync` again — which **resets `DistanceTraveledOnEdge` to 0 on the backend** (`WorldZoneService.cs:163`), making the character appear to not move and the progress bar to read 0% on the next refresh. Fix: (1) `world_map_detail_sheet.dart` progress-bar branch condition relaxed from `active && isDestination` to just `isDestination` so it matches the real `available + isDestination` state during travel; (2) `world_map_screen.dart` `_showZoneSheet` gained an explicit `else if (zone.isDestination)` branch that leaves `enterCallback = null`, preventing the accidental re-set-destination reset. `flutter analyze` on the two changed files surfaces only pre-existing `withOpacity` / `prefer_const_*` hints (no new issues). Backend unchanged — all 11 `WorldZoneServiceTests` still pass.

---

### LL-021 — World-map zone-arrival banner blocks input until dismissed
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: high
- **Phase**: bug
- **Reproduction**:
  1. Open the world map
  2. Travel to a crossroads / zone transition (via accumulated distance or `debug/add-distance`)
  3. "ZONE REACHED" banner slides down from the top
  4. Tap anywhere on the map — the tap dismisses the banner instead of reaching the map
- **Acceptance**:
  - [x] Banner still appears and slides in on zone arrival
  - [x] Banner never blocks taps on the map underneath (wrapped in `IgnorePointer`)
  - [x] Banner auto-dismisses after 2.5s with no user action
  - [x] Rapid-fire zone changes reset the timer (replace, don't stack)
  - [x] `flutter analyze` clean (no new issues; pre-existing `withOpacity` deprecations preserved)
- **Notes**: Root cause — `showGeneralDialog` always installs a hit-testable barrier. Replace with in-stack `AnimatedSlide` + `IgnorePointer` + `Timer`. File: `mobile/lib/features/map/world_map_screen.dart:284–338`.
- **Implemented**: commit pending — replaced `showGeneralDialog` with in-Stack `Positioned` + `IgnorePointer` + `AnimatedSlide`/`AnimatedOpacity` (350ms). New state: `_arrivalBanner` + `_arrivalBannerTimer`, cancelled in `dispose()` and replaced on rapid zone changes. One file changed: `mobile/lib/features/map/world_map_screen.dart` (+71/-48).

---

## 📋 Backlog

### LL-010 — Complete Garmin PKCE SHA-256 code challenge
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: medium
- **Phase**: P8
- **Acceptance**:
  - [ ] Add `crypto: ^3.0.3` to `pubspec.yaml`
  - [ ] `GarminService.generateCodeChallenge` uses `sha256` hashing (base64url-encoded)
  - [ ] `code_challenge_method=S256` sent in auth URL
  - [ ] Successful Garmin OAuth round-trip on a real device
- **Notes**: Currently falls back to plain text. Garmin may reject. See `docs/obsidian/07 - Development/Known Issues.md`.

### LL-011 — Random event spawner: Wandering Merchants
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui
- **Priority**: low
- **Phase**: P7
- **Acceptance**:
  - [ ] `Merchant` entity (zoneId, spawnedAt, expiresAt, stock[])
  - [ ] IHostedService spawns merchants in unlocked zones with 5–24h timer
  - [ ] `GET /api/merchants/active` returns current merchants for the user
  - [ ] Mobile merchant sheet UI shows stock + purchase flow
  - [ ] Purchased items are delivered via `ItemGrantService`
- **Notes**: Design-only today. See `docs/obsidian/02 - Game Design/Random Events.md`.

### LL-012 — Seasonal events (limited-time with 5-stage reward ladder)
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui
- **Priority**: low
- **Phase**: P7
- **Acceptance**:
  - [ ] `Season`, `SeasonReward`, `UserSeasonProgress` entities
  - [ ] Global ×2 XP multiplier active during event dates
  - [ ] Event-scoped leaderboard (start simple: in-memory list; Redis later)
  - [ ] Mobile event banner + reward-ladder widget
- **Notes**: Mockup `design-mockup/social/seasonal-events.html`. See `docs/obsidian/02 - Game Design/Seasonal Events.md`.

### LL-013 — Push notifications via Firebase Cloud Messaging
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui
- **Priority**: medium
- **Phase**: P8
- **Acceptance**:
  - [x] Firebase project configured, service-account key in `appsettings.json` _(project `life-level-ae77f`; key at `backend/src/LifeLevel.Api/firebase-admin-key.json`, gitignored)_
  - [x] `INotificationPort.SendAsync(userId, title, body, data)` in SharedKernel _(implemented as `SendToUserAsync` with extra `category` + `isCritical` params for cadence policy; `Ports/INotificationPort.cs`)_
  - [x] Mobile registers FCM token on login, POSTs to backend _(NotificationsService on MainShell init + auto-re-register on `onTokenRefresh`)_
  - [ ] Triggers wired: boss-spawn, XP-storm-start, streak-reminder-at-20h-idle _(**partial**: `StreakBrokenEvent` handler wired end-to-end as a working example; the three originally listed triggers each depend on infrastructure that doesn't exist yet — split out into LL-021, LL-022, LL-023)_
- **Notes**: Flutter needs `firebase_core` + `firebase_messaging` packages.
- **Implemented**: LL-013a vertical slice landed — new `LifeLevel.Modules.Notifications` module (entities, cadence-policy service, FCM adapter, repository, migration), `INotificationPort` in SharedKernel/Ports, `NotificationsController` with register/unregister endpoints, `StreakBrokenNotificationHandler` as the first live trigger. Mobile side: `firebase_core` + `firebase_messaging` added, `Firebase.initializeApp` wired in `main.dart`, new `NotificationsService` + `DeepLinkNotifier` cross-wire to the existing deep-link handler in `MainShell`. Backend: 97/97 tests pass (10 new cadence tests). Mobile: `flutter analyze` clean on new files, `flutter build apk --debug` exits 0. iOS push remains blocked by the [[iOS Pre-Testing Setup]] checklist. **Spin-off tickets queued:** LL-020 (`User.LastSeenAt` for in-app dedupe), LL-021 (`BossSpawnedEvent` + handler), LL-022 (XP storm scheduling + `XpStormStartedEvent`), LL-023 (streak reminder cron at 20h idle), LL-024 (per-category user preferences), LL-025 (encrypt device tokens at rest), LL-026 (transactional outbox — at-least-once event delivery), LL-027 (FCM batch send for fan-out).

### LL-014 — Friends system (add, list, activity feed)
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui
- **Priority**: low
- **Phase**: P8
- **Acceptance**:
  - [ ] `Friendship` entity (userA, userB, status: pending/accepted)
  - [ ] `POST /api/friends/request`, `POST /api/friends/accept`, `GET /api/friends`
  - [ ] Mobile Friends screen (list + pending requests + add-by-username)
  - [ ] Friends' recent activities visible in a feed

### LL-015 — Leaderboards (weekly XP, all-time level, friends)
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui
- **Priority**: low
- **Phase**: P8
- **Acceptance**:
  - [ ] Redis sorted sets for `xp:weekly`, `xp:all-time`, `level:all-time`
  - [ ] Hourly cron to refresh weekly from Activity table
  - [ ] `GET /api/leaderboards/{kind}?scope=global|friends` → top 100
  - [ ] Mobile leaderboard screen reachable from radial FAB
- **Notes**: Redis not yet in the stack — this ticket adds it.

### LL-016 — Guild system + shared-HP raid boss
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui
- **Priority**: low
- **Phase**: P8
- **Acceptance**:
  - [ ] `Guild`, `GuildMembership`, `GuildRaidState` entities
  - [ ] Create/join/leave endpoints
  - [ ] Raid boss with pooled HP across members
  - [ ] Top-DPS bonus XP at defeat
  - [ ] SignalR channel for live damage updates
- **Notes**: See `docs/obsidian/02 - Game Design/Boss System.md` — guild raids section.

### LL-017 — Encrypt Strava/Garmin tokens at rest
- **Layer**: backend
- **Agent**: backend
- **Priority**: high
- **Phase**: P8 (pre-prod)
- **Acceptance**:
  - [ ] `StravaConnection.AccessToken/RefreshToken` encrypted via ASP.NET Data Protection
  - [ ] Same for `GarminConnection`
  - [ ] Migration preserves existing dev rows
  - [ ] Decrypted on read, re-encrypted on write — transparent to callers
- **Notes**: `appsettings.json` secrets separate concern — this is token-column encryption.

### LL-018 — iOS HealthKit capability setup in Xcode
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: medium
- **Phase**: P8
- **Acceptance**:
  - [ ] `ios/Runner.xcworkspace` → Signing & Capabilities → HealthKit added
  - [ ] App builds + runs on a real iOS device
  - [ ] HealthKit permission prompt appears on first launch
  - [ ] Sample workout imports to backend
- **Notes**: Not doable from CLI — requires Xcode GUI step by the user. Agent may only document, not execute.

### LL-019 — Remove unused `go_router` dependency
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: low
- **Phase**: cleanup
- **Acceptance**:
  - [ ] `grep -r 'go_router' mobile/lib` returns zero matches
  - [ ] `go_router` removed from `pubspec.yaml`
  - [ ] `flutter pub get` succeeds
  - [ ] App builds and all screens still navigate correctly

### LL-020 — Transactional outbox for domain events
- **Layer**: backend
- **Agent**: backend
- **Priority**: low (escalates on first incident)
- **Phase**: P8
- **Acceptance**:
  - [ ] `OutboxMessages` table (Id, Type, Payload JSON, CreatedAt, ProcessedAt)
  - [ ] `IEventPublisher` writes event row inside the same SaveChanges
  - [ ] IHostedService polls and delivers to handlers
  - [ ] Retry + dead-letter after N failures
- **Notes**: Currently in-process delivery is not guaranteed — see `docs/obsidian/03 - Backend/Cross-Module Events.md` warning.

### LL-030 — Refactor home screen to match home-v3 mockup (all 4 screens + notifications sheet)
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: medium
- **Phase**: P8
- **Acceptance**:
  - [x] `HomeScreen` layout matches `design-mockup/home/home-v3.html` at 390×844 — compact header (avatar ring + greeting + streak chip + bell), slim 7-day streak strip, Adventure Hero card, compact stat strip (Banked km / Today's XP / Shields), Today's quests (3-preview + bonus hint), pinned "Log workout" CTA
  - [x] Adventure Hero card morphs through the 3 states per mockup — **Traveling** (blue glow, distance progress, "View on map"), **Arrived** (green glow, distance 100%, "Enter node"), **Boss Raid** (red glow, boss HP bar, "Fight"). Replaces the existing standalone `HomeBossCard`
  - [x] Removed from home (per v3 rationale comment): `HomeStatsRow`, `HomeMapHistoryCard`, `HomeRecentActivitiesCard`, `HomeMapProgressSection`, full `HomeStreakCard`. Verify each is still reachable via its destination tab (Profile / Map / Activity feed) before deleting
  - [x] Login reward chip wired to existing `login_reward_service.dart` — pending state with 7-pip tracker + Claim CTA; collapses to claimed variant after claim; hidden when no reward is due
  - [x] Bell button in header opens a bottom sheet with dim backdrop (Screen 4) — `NotificationsService` already exists; wire to the new `GET /api/notifications` endpoint from `NotificationsController.cs`. Each row deep-links via existing `DeepLinkNotifier`
  - [x] Backdrop dismisses sheet on tap; sheet has drag-to-dismiss; "Mark all read" action hits the controller
  - [x] XP Storm banner + Seasonal event row are rendered conditionally — **scaffold only** (widget + hidden-when-null state). Data wiring is out of scope (owned by LL-001 / LL-012)
  - [x] File split per the repo convention: screen = scaffold only, cards in `features/home/cards/`, widgets in `features/home/widgets/`. No monolithic `home_cards.dart`
  - [x] `flutter analyze` clean on changed files; app launches and all 4 screen states are reachable in debug
- **Notes**: Mockup at `design-mockup/home/home-v3.html` (inline comment block lines 535–610 documents what was moved off home and why). Current home is split across `home_screen.dart`, `home_cards.dart`, `home_widgets.dart`. Notifications controller migration: `20260417201912_AddNotificationsModule`. Login reward auto-modal is at `mobile/lib/core/shell/main_shell.dart:103` — the new chip is a re-entry point when the user dismisses that modal.
- **Implemented**: unstaged (not yet committed) — scaffold-only `home_screen.dart` composes 9 cards under `features/home/cards/`; notifications sheet lives under `features/notifications/` (models/services/providers/widgets) with `DraggableScrollableSheet` + mark-all-read; `flutter analyze` clean on `lib/features/home` + `lib/features/notifications`.
- **Caveats / follow-ups**:
  - Backend `GET /api/notifications` + mark-all-read endpoints don't exist yet — `NotificationsController.cs` only has `register-token`/`unregister-token`. Mobile wires to the expected routes with a 404 fallback (empty list). **Needs a backend follow-up ticket before the bell sheet shows real data.**
  - Old `HomeStreakCard` "Use Shield" action button no longer has a home surface. Shield *count* is on the stat strip; the action button needs a home (Profile streak screen, or a tap target on the Shields tile) — out of v3 scope.
  - `HomePulsingLvBadge` (tap-to-open-level-up-recap on avatar) dropped per v3 mockup. If we want the interaction back, follow-up on avatar ring.

### LL-028 — Level-gated feature unlocks (weekly challenges, gear slots)
- **Layer**: backend, mobile
- **Agent**: backend, flutter-ui, game-engine
- **Priority**: low
- **Phase**: P6
- **Acceptance**:
  - [ ] Design: decide which features are level-gated and at what levels (gear slots: gloves@L3, helm@L5 …; weekly challenges@L5; etc.)
  - [ ] New entity/config table `LevelFeatureUnlock(Level, FeatureKey, DisplayName, Description, Icon)`
  - [ ] `IFeatureUnlockReadPort.GetFeaturesUnlockedInRangeAsync(prev, new)` in SharedKernel
  - [ ] `LevelUpUnlocksDto` extended with `UnlockedFeatures`; populated in `ActivityService.LogActivityAsync`
  - [ ] Mobile level-up overlay renders feature unlocks alongside items/zones
  - [ ] Downstream enforcement: gated features check unlock state before allowing access (inventory gear-slot gate, weekly quest query, etc.)
- **Notes**: Follow-up to the level-up popup "UNLOCKED" section work. Items + zones + stat points are already real; this ticket extends the same DTO with feature gates. Requires game-design decisions on what should be gated before coding.

### LL-031 — Local Map history sheet (top-right icon → bottom sheet)
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: low
- **Phase**: P3
- **Acceptance**:
  - [x] Small circular history FAB rendered on `MapScreen` at `top: 48, right: 16`, matching the visual style of the existing bottom-right FABs (`FloatingActionButton.small`, translucent tint, icon child — use `Icons.history`, background `AppColors.orange.withOpacity(0.85)`)
  - [x] FAB does not overlap the centered `_buildHud()` pill (pill stays centered; icon sits to its right)
  - [x] Tapping the FAB opens a bottom sheet (`showModalBottomSheet`, `isScrollControlled: true`, `backgroundColor: Colors.transparent`) — **not** a full-screen route
  - [x] Sheet shows the same list `MapHistoryScreen` shows today: current node highlighted at top, then completed/unlocked nodes newest-first, with `+XP`, status text ("Just arrived!", "Cleared", "Defeated", "Path chosen", "Opened", "Completed") and node-type colour pill
  - [x] Sheet visually matches `XpHistorySheet` (drag handle, `Color(0xFF0f1828)` surface, rounded top corners, icon+title header, divider-separated list, empty state)
  - [x] Empty state copy: "No nodes visited yet." (same as current `MapHistoryScreen`)
  - [x] `MapScreen` is converted to `ConsumerStatefulWidget` (or a `Consumer` is pushed down the tree) so the sheet can `ref.watch(mapJourneyProvider)`
  - [x] Swipe-down / tap-outside dismisses the sheet; the map state underneath is unaffected
  - [ ] Manual verification on device: tap the new top-right history icon inside a zone, confirm sheet slides up, current/completed nodes render correctly, sheet dismisses without resetting the map

- **Notes**:
  - Reuse `mapJourneyProvider` from `mobile/lib/features/home/providers/map_journey_provider.dart`.
  - New file: `mobile/lib/features/map/map_history_sheet.dart`. Skeleton from `mobile/lib/features/profile/xp_history_sheet.dart`; row rendering + status/colour helpers from `mobile/lib/features/map/map_history_screen.dart` (lines 99-197).
  - `MapHistoryScreen` is currently orphaned (no route points to it). Leave it in place here; a follow-up ticket can delete it once the sheet is proven.
  - Reference FABs for visual parity: `map_screen.dart:410-419` (🌍 world map, blue) and `map_screen.dart:420-429` (🛠️ debug, purple). Use orange for history so the three don't collide visually.
  - Plan file: `.claude/plans/unified-cuddling-koala.md`.
- **Implemented**: commit pending — `MapScreen` converted to `ConsumerStatefulWidget`, new orange `Icons.history` FAB at `top: 48, right: 16` opens `MapHistorySheet` via `showModalBottomSheet` (0.85 heightFactor), with `ref.invalidate(mapJourneyProvider)` on open so the sheet always sees fresh data. New sheet file mirrors `XpHistorySheet` shell + copies `_HistoryEntry`/`_nodeTypeColor`/`_completedStatusText` verbatim from `map_history_screen.dart` (orphaned screen untouched). Two files changed: `mobile/lib/features/map/map_screen.dart` (+31/-3), `mobile/lib/features/map/map_history_sheet.dart` (new, 265 lines). `flutter analyze` on the touched files surfaces only pre-existing `withOpacity` deprecations (codebase-wide pattern, no new issues).

### LL-032 — Backend notifications feed endpoints (`GET /api/notifications` + mark-all-read)
- **Layer**: backend
- **Agent**: backend
- **Priority**: medium
- **Phase**: P8
- **Acceptance**:
  - [ ] `GET /api/notifications` returns the current user's notification list (id, category, title, body, deepLinkPath, unread, createdAt), newest-first, paginated
  - [ ] `POST /api/notifications/mark-all-read` (or PATCH) marks every unread notification for the user as read and returns the updated count
  - [ ] Per-row `POST /api/notifications/{id}/mark-read` for single-row interactions (mobile taps a row → deep-link + mark read)
  - [ ] DTO shape aligned with `mobile/lib/features/notifications/models/notification_list_models.dart` (NotificationItem + NotificationCategory enum values: `bossSpawn`, `streakAtRisk`, `questComplete`, `xpStorm`, `friendActivity`, `generic` — confirm/rename as needed)
  - [ ] Unit tests: list empty, list paginated, mark-all-read idempotency, auth isolates users
- **Notes**: Follow-up from LL-030. Current `NotificationsController.cs` only has `register-token` / `unregister-token`. Mobile already wires to these routes with a 404 fallback — once these endpoints ship, the home bell sheet shows real data with zero mobile changes. Notifications module already exists at `backend/src/modules/LifeLevel.Modules.Notifications/` — extend it.

### LL-033 — Re-home "Use Shield" action button after home-v3 streak compression
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: low
- **Phase**: P8
- **Acceptance**:
  - [ ] Decide target surface — recommended: tap on the Shields tile in `home_stat_strip.dart` opens a bottom sheet with shield count + "Use Shield" CTA, OR a dedicated streak detail screen reachable from the Profile tab
  - [ ] "Use Shield" flow preserved from the old `HomeStreakCard` (calls existing streak service, consumes one shield, protects today)
  - [ ] Longest-streak stat still surfaces somewhere (Profile activity summary is a candidate)
  - [ ] `flutter analyze` clean on changed files
- **Notes**: Follow-up from LL-030. The v3 mockup dropped the full `HomeStreakCard` — shield *count* moved to the stat strip and the 7-day grid compressed into `HomeStreakStrip`, but the original "Use Shield to protect streak" action button has no home. Current shield count read lives in `mobile/lib/features/home/cards/home_stat_strip.dart`. Pre-v3 implementation lived in the (now-deleted) `home_cards.dart` — check git history for the exact call if needed.

### LL-035 — First-time user tutorial (floating bubble coach marks + topic tutorials hub)
- **Layer**: backend, mobile, game-engine
- **Agent**: backend, flutter-ui, game-engine
- **Priority**: high
- **Phase**: P2
- **Acceptance**:
  - [x] `Character` entity: `TutorialStep` (int, default 0, -1 = skipped), `TutorialCompletedAt` (DateTime?), `TutorialRewardsClaimed` (bool, default false), `TutorialTopicsSeen` (int bitmask, default 0) + EF migration `20260419090159_AddTutorialProgress` (4 columns on `Characters` table; run `dotnet ef database update` to apply)
  - [x] `POST /api/tutorial/advance` — increments step 0→7, awards step XP only when `TutorialRewardsClaimed == false`, sets the bit for the completed topic in `TutorialTopicsSeen`. Wrong-step advance is a no-op; step-4 via controller throws (port-only).
  - [x] `POST /api/tutorial/skip` — sets `TutorialStep = -1`, no XP, no title
  - [x] `POST /api/tutorial/replay-all` — resets `TutorialStep = 0`, `TutorialCompletedAt = null`. Does NOT reset `TutorialRewardsClaimed` (rewards stay one-shot).
  - [x] `POST /api/tutorial/replay-topic` with `{ topic: "xp-stats" \| "quests-streaks" \| "activity-logging" \| "world-map" \| "boss-system" }` — marks the bit in `TutorialTopicsSeen`, does not change `TutorialStep`. Unknown topic → 400.
  - [x] Game-engine: `TutorialStepRewards` static table (step 1–6 small XP totalling 250; step 7 +250 + "Novice Adventurer" title). Title unlock only if `TutorialRewardsClaimed == false`. `TitleUnlockAdapter` + `ITitleUnlockPort` added; catalog entry `novice-adventurer` seeded.
  - [x] `CharacterProfile` DTO exposes `tutorialStep` and `tutorialTopicsSeen` so the mobile hub can render ✓ / ○ state
  - [x] `ICharacterTutorialPort.AdvanceIfOnStepAsync(characterId, expectedStep)` in SharedKernel (follows `ICharacterXpPort.cs` pattern)
  - [x] `ActivityService.LogActivityAsync` + `LogActivityFromExternalAsync` call `AdvanceIfOnStepAsync(characterId, 4)` after a successful log (wrapped in try/catch so tutorial never breaks logging)
  - [x] Mobile: `features/tutorial/` feature folder — `tutorial_controller.dart` (state machine, reads `GlobalKey` rects, picks bubble placement), `providers/`, `services/tutorial_service.dart` (4 API calls), `models/tutorial_step.dart` + `tutorial_topic.dart` + `tutorial_placement.dart`, `widgets/tutorial_bubble.dart`, `widgets/tutorial_bubble_tail.dart` (CustomPainter triangle), `widgets/tutorial_dim_backdrop.dart` (full-screen dim + pulse-ring painter), `widgets/tutorial_skip_sheet.dart`, `screens/tutorial_intro_screen.dart`, `screens/tutorial_outro_screen.dart`, `screens/tutorials_hub_screen.dart`
  - [x] Bubble is 290px wide × auto height, rounded 14px, dark surface (`#1e2632`), 1px accent border, 14px tail painted toward target, step-specific accent colour (1 blue, 2 purple, 3 orange, 4 blue, 5 green, 6 red)
  - [x] Bubble placement algorithm implements 4-case rule: above / below / above-right-offset / above-FAB — derived from target global rect
  - [x] 6 `GlobalKey`s wired: `xpCard` → HomeAdventureHero, `statsRow` → HomeStatStrip, `questsCard` → HomeTodaysQuestsCard, `logFab` + `bossFab` → Boss FAB (shared physical target, different step copy), `mapTab` → ShellNavBar per-tab key
  - [x] Tutorial auto-starts on `MainShell` first build when `tutorialStep == 0`, resumes from any intermediate step on relaunch (via `hydrateFromProfile`)
  - [x] Step 4 shows disabled "Waiting…" button until `ActivityService` server-advances; next profile refresh resumes the flow at step 5
  - [x] Intro (step 0) and outro (step 7) full-screen modals reuse `character-setup.html` tokens (radial backdrop, progress dots, gradient CTA)
  - [x] Skip button on every bubble opens a confirmation sheet; confirmed Skip calls `/skip` endpoint
  - [x] Profile settings sheet gains a **"Tutorials"** row above "Logout" → pushes `TutorialsHubScreen`
  - [x] Hub shows: "Play all" primary row (accent blue, "6 steps · +0 XP on replay"), then 5 topic rows (XP & Stats / Quests & Streaks / Activity Logging / World Map / Boss System) with ✓ / ○ status from `tutorialTopicsSeen` bitmask
  - [x] Tapping "Play all" pops hub + settings and restarts the full flow from step 0 (no XP re-awarded)
  - [x] Tapping a topic row pops hub + settings and runs that topic's bubble(s) on Home — no outro, no XP
  - [~] Backend unit tests: **`dotnet test` → 126 Passed / 0 Failed / 0 Skipped** (includes game-engine sibling's `TutorialStepRewardsTests`). Dedicated `TutorialServiceTests` covering the 6 named scenarios (advance happy path, wrong-step no-op, skip idempotent, replay-all does-not-re-award, replay-topic bit-only, activity-gated advance) are **not yet written** — follow-up sub-ticket recommended.
  - [x] `flutter analyze` clean on all new/changed mobile files (tutorial feature + shell + home + profile = 0 issues)
- **Notes**:
  - Plan: `.claude/plans/humming-enchanting-flask.md`
  - Design mockup: `design-mockup/onboarding/tutorial-coachmarks.html` — Variant B floating bubble frames for every step, plus Tutorials Hub, Skip Confirmation, and XP Reward Toast states. Variant A kept as runner-up reference.
  - Obsidian doc to add: `docs/obsidian/04 - Mobile App/Features/Feature - Tutorial.md`
  - **No new Flutter dependency** — tail is a `CustomPainter` triangle (~30 LOC).
  - **Read `backend/ARCHITECTURE.txt` first** — confirm module boundary and port/adapter rules before adding the Tutorial module / port.
  - Step flow: 0 intro → 1 XP bar (+25) → 2 stats (+25) → 3 quests+streak (+50) → 4 activity-log (+50, gated on real log) → 5 map (+50) → 6 boss FAB (+50) → 7 outro (+250 + Novice title). Total 500 XP on first completion. Replay grants 0 XP.
- **Implemented**: commit pending (unstaged) — backend: `Character` fields + EF migration `20260419090159_AddTutorialProgress` + `TutorialStepRewards` + `TutorialTopic` + `ICharacterTutorialPort` + `ITitleUnlockPort` + `TitleUnlockAdapter` + `TutorialController` + 4 endpoints + Activity port call + `TutorialDtos` + `TitleCatalog` novice entry + `TutorialStepRewardsTests`; mobile: full `features/tutorial/` feature (controller/provider/widgets/screens — 12 files + placement/step/topic models + service aligned to DTO shape), MainShell integration (key registration + hydrate + intro/outro route push + overlay wrap + map-tab key wire), profile Settings row, home_screen converted to ConsumerStatefulWidget with 3 card GlobalKeys, `ShellNavBar.keysByTabId` plumbing. **Verification:** `dotnet build` clean (0 errors); `dotnet test` **126/126 pass**; `flutter analyze` **0 issues** on all new/changed files. Still pending: run `dotnet ef database update`, manual device QA, and a follow-up sub-ticket for the 6 dedicated `TutorialServiceTests` scenarios. Three parallel agents on first dispatch hit stream idle timeout; salvaged completed work from disk and filled remaining gaps manually + via one narrower re-dispatched flutter-ui agent.

---

### LL-034 — Restore tap-to-open level-up recap on home avatar (post-v3)
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: low
- **Phase**: P8
- **Acceptance**:
  - [ ] Tapping the `HomeAvatarRing` in `home_header.dart` opens the level-up recap overlay (the one `LevelUpNotifier` broadcasts on actual level-up) showing the most recent level-up's unlocks
  - [ ] If no level-up has happened yet, tap is a no-op (or shows a subtle "Level up to see your rewards here" tooltip)
  - [ ] Works alongside existing `LevelUpNotifier` listener in `main_shell.dart` — tap-to-replay should not double-fire if an organic level-up is already in-flight
  - [ ] `flutter analyze` clean
- **Notes**: Follow-up from LL-030. v3 mockup dropped `HomePulsingLvBadge` (pulsing LV badge on the avatar that opened the overlay). If we still want re-entry to the recap, add it back via the avatar ring — not the pulsing badge, which clashed with the v3 compact-header aesthetic.

---

## ✅ Completed

> Tickets shipped with all acceptance criteria met. Each has an `Implemented:` line pointing at the landing commit. Historic phase-level wins (P0–P6 bulk work) live in the "Done (summary)" section below; individual tickets closed going forward go here.

### LL-002 — Replace hardcoded HomeLastActivityCard with real feed
- **Layer**: mobile
- **Agent**: flutter-ui
- **Priority**: medium
- **Phase**: P1 tail
- **Acceptance**:
  - [x] Card pulls from `activityHistoryProvider` (last activity)
  - [x] Empty state when no activities exist yet
  - [x] Loading shimmer while fetching
  - [x] Tap card navigates to `RecentActivitiesScreen`
- **Notes**: Memory reference `project_recent_activities_plan.md` — plan file at `buzzing-baking-patterson.md`.
- **Implemented**: commit e00278c — `HomeRecentActivitiesCard` + `RecentActivitiesScreen` + `activityHistoryProvider` wired up; old hardcoded `HomeLastActivityCard` removed. Minor caveat on the tap-navigation criterion: only the "View all →" action triggers navigation, not the entire card surface — treated as intentional UX.

---

## ✅ Done (summary)

Rather than list every completed ticket, the Phase-level status lives in `docs/obsidian/01 - Product/Roadmap Status.md`. Condensed:

- **Phase 0 (Foundation)** — ASP.NET Core + JWT + EF Core + Flutter scaffold + design system
- **Phase 1 (Character & Activity)** — Character entity, XP engine, 8 activity types, stat system, home + profile screens
- **Phase 2 (Quests & Login)** — Daily/weekly/special quests, streak + shields, 7-day login cycle
- **Phase 3 (Adventure Map)** — World zones + dungeon map graphs, distance-driven travel
- **Phase 4 (Bosses)** — Regular + mini bosses, damage formula, timer expiry (guild raids in Backlog)
- **Phase 5 (Items & Equipment)** — 21-item catalog, 5 slots, drop rules, gear XP bonus
- **Phase 6 (Titles, Ranks, Achievements)** — 48 achievements, rank ladder, equippable titles
- **Partial Phase 8** — Strava OAuth + webhook, Health Connect sync, admin web panel, connectivity auto-refresh

---

## How the agent uses this file

1. `/work-next-ticket` reads this file, picks the first ticket under "🟡 In Progress".
2. It summarises the ticket back to the user for approval before coding.
3. It dispatches to the named `Agent:` subagent (backend / flutter-ui / game-engine).
4. It implements only what "Acceptance" lists (scope fence).
5. It appends an `✅ Implemented (commit SHA)` line to the ticket — but does NOT move the ticket to Done. That's the user's call after reviewing the diff.
6. If acceptance criteria are ambiguous, it stops and asks before writing code.
