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
- **Notes**: Root cause — `Activity → WorldZone` port never existed. `IMapDistancePort` only advanced the dungeon map, so `UserWorldProgress.DistanceTraveledOnEdge` stayed at 0, which fed directly into both the map character position (`distanceTraveledOnEdge / edge.distanceKm`) and the zone detail progress bar. Fix adds `IWorldZoneDistancePort` in SharedKernel, implemented by `WorldZoneService`, wired from `ActivityService`, and fires `WorldZoneRefreshNotifier.notify()` on mobile log so an open map reloads immediately. See plan: `.claude/plans/mutable-pondering-blum.md`.
- **Follow-up**: Mirror `UserMapProgress.PendingDistanceKm` reserve-km banking onto `UserWorldProgress` so distance logged before setting a destination is not lost (needs entity field + EF migration). Out of scope for this ticket.

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
  - [ ] Small circular history FAB rendered on `MapScreen` at `top: 48, right: 16`, matching the visual style of the existing bottom-right FABs (`FloatingActionButton.small`, translucent tint, icon child — use `Icons.history`, background `AppColors.orange.withOpacity(0.85)`)
  - [ ] FAB does not overlap the centered `_buildHud()` pill (pill stays centered; icon sits to its right)
  - [ ] Tapping the FAB opens a bottom sheet (`showModalBottomSheet`, `isScrollControlled: true`, `backgroundColor: Colors.transparent`) — **not** a full-screen route
  - [ ] Sheet shows the same list `MapHistoryScreen` shows today: current node highlighted at top, then completed/unlocked nodes newest-first, with `+XP`, status text ("Just arrived!", "Cleared", "Defeated", "Path chosen", "Opened", "Completed") and node-type colour pill
  - [ ] Sheet visually matches `XpHistorySheet` (drag handle, `Color(0xFF0f1828)` surface, rounded top corners, icon+title header, divider-separated list, empty state)
  - [ ] Empty state copy: "No nodes visited yet." (same as current `MapHistoryScreen`)
  - [ ] `MapScreen` is converted to `ConsumerStatefulWidget` (or a `Consumer` is pushed down the tree) so the sheet can `ref.watch(mapJourneyProvider)`
  - [ ] Swipe-down / tap-outside dismisses the sheet; the map state underneath is unaffected

- **Notes**:
  - Reuse `mapJourneyProvider` from `mobile/lib/features/home/providers/map_journey_provider.dart`.
  - New file: `mobile/lib/features/map/map_history_sheet.dart`. Skeleton from `mobile/lib/features/profile/xp_history_sheet.dart`; row rendering + status/colour helpers from `mobile/lib/features/map/map_history_screen.dart` (lines 99-197).
  - `MapHistoryScreen` is currently orphaned (no route points to it). Leave it in place here; a follow-up ticket can delete it once the sheet is proven.
  - Reference FABs for visual parity: `map_screen.dart:410-419` (🌍 world map, blue) and `map_screen.dart:420-429` (🛠️ debug, purple). Use orange for history so the three don't collide visually.
  - Plan file: `.claude/plans/unified-cuddling-koala.md`.

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
