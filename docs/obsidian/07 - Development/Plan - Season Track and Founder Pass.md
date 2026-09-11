---
tags: [lifelevel, plan, season, battle-pass, monetization]
aliases: [Season Track, Founder Pass, Battle Pass]
status: built
---
# Plan — Season Track & Founder Pass

> **Build status (backend + admin + mobile done; Home banner deferred).**
> Verified against the live API on :5128 — `GET /api/season`, flat Season-XP accrual
> (3×running 30m/5km = 630 exactly), claim gating (409 not-reached / 409 already-claimed /
> 403 no-pass), `pass/purchase` (+250 XP applied), admin `restart` (wipes progress/claims/pass,
> resets timer), and `SeasonRolloverJob` (auto-grants reached-but-unclaimed tiles → +500 char XP
> delta, season → Ended). `flutter analyze` clean; app boots; Season Track reachable from the
> radial-ring 🎫 item and `lifelevel://season`. Not yet exercised: a live click-through of the
> Flutter screen (needs the Chrome extension; Flutter-web canvas isn't automatable here).

> Season 1 "Trail of Embers": a 25-tier, two-lane (Free + **Founder**) battle-pass, its
> Season-XP accrual, an admin control page (configure / activate / **restart**), and a
> **self-contained** Flutter Season Track screen + Founder Pass buy page. Payment is out of
> scope — the entitlement gate is built and exercised, "purchase" just grants it.
> **The Home-screen season banner is out of scope this iteration** (deferred).

## Context

Life-Level has no season / battle-pass system today. [[Seasonal Events]] is design-only
(Phase 7), and a grep of `backend/src` for `season` finds nothing but a stray "seasoned" in a
rank description. The **UI was already designed** on the Command Center canvas (artifact
`63d23408-559f-4a6a-a6bc-6f6cdce93120`): `Season.dc.html` / `Season2.dc.html` (the track, four
tile states, Free + Founder lanes, Season-XP bar, countdown, Tier-25 milestone), plus
**`FounderPass.dc.html`** (buy page + entry points) and **`HomeSeason.dc.html`** (deferred Home
banner spec). Sources in `design-mockup/canvas-command-center/`.

### Decisions locked with the user

| Question | Decision |
|---|---|
| Premium track name | **Founder Pass** (lane label "Founder", every season) |
| Season 1 length | **8 weeks / 56 days** |
| How Season XP is earned | **Separate flat values**, independent of the level-XP curve |
| Unclaimed rewards at season end | **Auto-granted** when the season closes (nothing lost) |
| Home-screen entry point | **Out of scope this iteration** — reach via radial-ring item + `lifelevel://season` deep link only |

Further defaults:

- **Season Track surface** = a shell overlay screen reached from a radial-ring item + the deep
  link — mirrors `titles` / `boss` / `guild` (`main_shell.dart`). Not a 5th bottom-nav tab.
- **Restart** = hard reset for pre-launch testing: reset the timer to `now … now+56d` and wipe
  every user's progress / claims / Founder-pass rows *for that season*.
- **Founder Pass in test builds** = an in-app "Unlock" button that creates the entitlement with
  no payment (`Source = Purchase`), plus admin grant/revoke. Buying does **not** auto-claim —
  it flips reached Founder tiles to `ready` so the player still taps to collect.

---

## Backend — `LifeLevel.Modules.Seasons`

New module, same shape as `LifeLevel.Modules.LoginReward` / `Quest` (see
`backend/ARCHITECTURE.txt`). One shared `AppDbContext`, one migrations project
(`LifeLevel.Api/Migrations`).

### Entities (`Domain/Entities/`)

- **`Season`** — `Id`, `Number`, `Name` ("Trail of Embers"), `Theme` (slug `ember` / `tide` —
  drives the mobile accent), `StartsAt`, `EndsAt`, `State` (`Scheduled | Active | Ended`),
  `XpPerTier` (default **600**), `TierCount` (default **25**), `MilestoneTier` (default 25).
- **`SeasonRewardTier`** — `Id`, `SeasonId` (FK), `Tier` (1..N), `Track` (`Free | Founder`),
  `RewardType` (`SeasonXp | Xp | Item | StreakShield | Title | Cosmetic`), `RewardRefId`
  (nullable `Guid` — item id), `RewardKey` (nullable string — title catalog key), `Amount`
  (int), `Label` ("Ember Cache"), `IconKey` ("reward_treasure_chest"), `Rarity` (nullable).
  One row per (season, tier, track). Seeded, admin-editable.
- **`UserSeasonProgress`** — `Id`, `UserId` (FK, cascade), `SeasonId` (FK), `SeasonXp` (long),
  `CurrentTier` (cache = `min(TierCount, SeasonXp / XpPerTier)`), `UpdatedAt`. One per
  (user, season), created lazily.
- **`UserSeasonClaim`** — `Id`, `UserId`, `SeasonId`, `Tier`, `Track`, `ClaimedAt`,
  `WasAutoGranted` (bool). Presence = "claimed" (idempotency, like `LoginReward.ClaimedToday`
  but per tile). Unique `(UserId, SeasonId, Tier, Track)`.
- **`UserFounderPass`** — `Id`, `UserId`, `SeasonId`, `AcquiredAt`, `Source`
  (`Purchase | AdminGrant | Auto`). Presence = entitlement. Unique `(UserId, SeasonId)`. The
  greenfield paywall gate — zero existing premium/entitlement concept in the backend.

EF config: per-entity `IEntityTypeConfiguration<T>` under
`Infrastructure/Persistence/Configurations/` (enums `.HasConversion<string>()`, matching
`QuestConfiguration.cs`). Cross-module FKs (`UserSeason* → User`) inline in
`AppDbContext.OnModelCreating` next to the existing `LoginReward → User` block. Add the four
`DbSet`s + `ApplyConfigurationsFromAssembly(typeof(SeasonsModule).Assembly)`.

### Season XP accrual (flat values)

New `Domain/SeasonXpRules.cs` — pure static, single source of truth:

```csharp
// per activity logged
int Base(ActivityType t) => t switch {
    Running or Cycling => 120, Gym => 120, Swimming or Climbing => 110,
    Hiking => 100, Yoga => 90, _ => 90 };
int ForActivity(ActivityType t, int durationMin, double distanceKm) =>
    Base(t) + 2 * durationMin + (int)(6 * distanceKm);   // cardio distance rewarded
const int PerQuestComplete = 40;
const int PerBossDefeat    = 300;
```

Event-driven (no edits to Activity/Quest/Boss services) — the module registers in-process
handlers, exactly like [[Notifications]]:

- `IEventHandler<ActivityLoggedEvent>` → `+ SeasonXpRules.ForActivity(...)`
- `IEventHandler<QuestCompletedEvent>` → `+ PerQuestComplete`
- `IEventHandler<BossDefeatedEvent>` → `+ PerBossDefeat`

Each calls `SeasonService.AddSeasonXpAsync(userId, amount)` — no-ops with no `Active` season,
else bumps `SeasonXp`, recomputes `CurrentTier`, saves. Crossed tiers become `ready`; nothing
auto-claims mid-season. All three events already exist in `SharedKernel/Events` and are already
published.

### Claim / entitlement / rollover — `Application/UseCases/SeasonService.cs`

Ctor deps (all existing owners, no DI cycle — none depend back on Seasons):
`DbContext db, ICharacterXpPort xp, IStreakShieldPort shields, ITitleUnlockPort titles,
ICharacterIdReadPort charIds, IItemRewardGrantPort items, IEventPublisher events`.

- **`IItemRewardGrantPort`** is **new** (`SharedKernel/Ports/`) — no generic cross-module item
  grant exists (only the level-gated `ILevelUpItemGrantPort`). Implement in the Items module as
  a thin adapter over `ItemGrantService.GrantItemAsync(userId, itemId, ct)` (idempotent,
  inventory-cap aware), registered in `AddItemsModule()`. Mirrors `LevelUpItemGrantPortAdapter.cs`.

- **`ClaimTierAsync(userId, seasonId, tier, track, auto=false)`** — shared by the endpoint and
  the rollover job:
  1. load season + `UserSeasonProgress`;
  2. `tier > progress.CurrentTier` → `InvalidOperationException("Tier not reached")` (→ 409);
  3. `track == Founder` && no `UserFounderPass` → `UnauthorizedAccessException` (→ 403);
  4. existing `UserSeasonClaim` → `InvalidOperationException("Already claimed")` (→ 409);
  5. resolve `SeasonRewardTier`, grant by `RewardType`:
     `Xp` → `xp.AwardXpAsync(userId,"Season","🎫",label,Amount)`;
     `Item` → `items.GrantAsync(userId, RewardRefId)`;
     `StreakShield` → `shields.AddShieldAsync(userId)` ×`Amount`;
     `Title` → `titles.UnlockAsync(await charIds.GetCharacterIdAsync(userId), RewardKey)`;
     `SeasonXp` → flavor only (adds to `SeasonXp`);
     `Cosmetic` → v1 records the claim only (no backing system yet);
  6. insert `UserSeasonClaim { WasAutoGranted = auto }`, save;
  7. return `SeasonClaimResult(Label, XpAwarded, LeveledUp, NewLevel?, GrantedItemName?)`.

- **`PurchaseFounderPassAsync(userId)`** — `Active` season required; idempotent; inserts
  `UserFounderPass { Source = Purchase }`. `// TODO: gate behind real IAP receipt validation`.
  Returns the refreshed track.

- **`GetTrackAsync(userId)`** → the DTO the mobile screen renders.

- **`ISeasonRolloverPort.RolloverDueSeasonsAsync(ct)`** (new port, `SharedKernel/Ports/`, impl
  on `SeasonService`) — for each `Active` season past `EndsAt`: `ClaimTierAsync(auto: true)`
  every reached-but-unclaimed tile (Free always; Founder only where the pass exists) →
  **auto-grant**; then `season.State = Ended`; if a `Scheduled` season has `StartsAt <= now`,
  set it `Active`.

### Scheduled job

`LifeLevel.Api/Application/BackgroundJobs/SeasonRolloverJob.cs` — `BackgroundService`, fixed
`Interval = TimeSpan.FromMinutes(10)`, resolves `ISeasonRolloverPort` from a fresh scope; copy
`GuildRaidExpiryJob.cs`. Register `AddHostedService<SeasonRolloverJob>()` in `Program.cs`.

### Seeder

`LifeLevel.Api/Infrastructure/Persistence/SeasonSeeder.cs` — runtime idempotent seeder (pattern
of `AchievementSeeder` / `RankThresholdSeeder`): if no `Season` rows, insert Season 1
"Trail of Embers" (`Number=1`, `Theme="ember"`, `StartsAt=now`, `EndsAt=now+56d`,
`State=Active`, `XpPerTier=600`, `TierCount=25`) + its `SeasonRewardTier` rows from a static
`SeasonOneCatalog`. Register + invoke in the `Program.cs` startup scope.

### Season 1 reward catalog (25 tiers × 2 lanes — starting point)

Built only from primitives grantable for real today; Founder lane is deliberately richer.
`SeasonXp` amounts are flavor; `Xp` amounts hit the real character.

| Tier | Free lane | Founder lane |
|---|---|---|
| 1 | +150 Season XP | +250 XP |
| 2 | +250 XP | Streak Freeze ×1 |
| 3 | Streak Freeze ×1 | +400 XP · +150 Season XP |
| 4 | +200 Season XP | Item: *Iron Headband* (common) |
| 5 | +300 XP | Title: **"The Marathoner"** |
| 6 | +300 Season XP | Item: *Storm Jacket* (uncommon) |
| 7 | Item: *Ember Cache → Zone Compass* (common) | +600 XP · Streak Freeze ×1 |
| 8 | +400 XP | Item: *Speed Spikes* (uncommon) |
| 9 | Streak Freeze ×1 | +500 Season XP · +400 XP |
| 10 | +400 Season XP | Item: *Champion Gloves* (**epic**, +XP%) |
| 11–14 | alternating +XP / Season XP / Streak Freeze | +XP + one uncommon item each |
| 15 | Title: **"Streak Master"** booster (+600 XP) | Title: **"Raid Veteran"** |
| 16–19 | +XP / Season XP | +XP + rare items |
| 20 | Item: rare gear (+XP%) | Item: **epic** gear (+stat) |
| 21–24 | +XP / Season XP | +XP + Cosmetic *(placeholder)* |
| 25 (milestone) | +1500 XP · "Trailblazer" recognition | **"Ember Aura"** Cosmetic *(placeholder)* + epic item + Title **"The Champion"** |

Item ids resolve against `ItemSeeder`, titles against `TitleCatalog.cs` keys. Admin can rewrite
any row before go-live.

### API surface (`LifeLevel.Api/Controllers/`)

**`SeasonController.cs`** — `[Route("api/season")] [Authorize]`, injects `SeasonService` +
`IUserContext`:
- `GET /api/season` → `SeasonTrackResponse` — `{ season:{number,name,theme,endsAt,daysLeft},
  xpPerTier, currentTier, tierCount, seasonXp, xpIntoTier, xpToNextTier, hasFounderPass,
  nextReward:{tier,label,track}, tiers:[{tier, free:{...,state}, founder:{...,state}}] }`;
  `state ∈ received|locked|pending|ready` (pending = the one next tier).
- `POST /api/season/claim` `{ tier, track }` → `SeasonClaimResult`;
  `InvalidOperationException`→409, `UnauthorizedAccessException`→403 (like `LoginRewardController`).
- `POST /api/season/pass/purchase` → refreshed `SeasonTrackResponse`.

**`Controllers/Admin/AdminSeasonsController.cs`** — `[Route("api/admin/seasons")]
[Authorize(Policy = "Admin")]`, injects `AppDbContext` + `ISeasonRolloverPort` (template:
`AdminRankThresholdsController.cs`):
- `GET /api/admin/seasons` — list seasons + tier rows.
- `POST /api/admin/seasons` — create a `Scheduled` season.
- `PUT /api/admin/seasons/{id:guid}` — edit season fields.
- `PUT /api/admin/seasons/{id:guid}/tiers/{tier:int}/{track}` — upsert one reward row.
- `POST /api/admin/seasons/{id:guid}/activate` — set `Active`, others `Ended`.
- `POST /api/admin/seasons/{id:guid}/restart` — **the restart button**: `StartsAt=now`,
  `EndsAt=now+(EndsAt-StartsAt)`, `State=Active`, `db.RemoveRange` all `UserSeasonProgress` /
  `UserSeasonClaim` / `UserFounderPass` for that season.
- `POST /api/admin/seasons/pass/grant` `{ userIdOrEmail }` / `.../pass/revoke` — Founder Pass
  grant/revoke for testers (`Source = AdminGrant`).

### DI + migration

`Infrastructure/SeasonsModule.cs` (`AddSeasonsModule`): scoped `SeasonService` aliased to
`ISeasonRolloverPort`; register the three `IEventHandler<…>`; register `IItemRewardGrantPort`
in `AddItemsModule()`. Add `using` + `AddSeasonsModule()` to `Program.cs` after
Character/Items/Streak/Quest.

Migration: `dotnet ef migrations add AddSeasonsModule --project src/LifeLevel.Api
--startup-project src/LifeLevel.Api` (auto-applied at startup).

---

## Admin web UI

Vanilla multi-page static HTML in `backend/src/LifeLevel.Api/wwwroot/admin/` — no build step.

- **New `wwwroot/admin/seasons.html`** — copy `rank-thresholds.html` verbatim (theme `:root`
  vars + `getToken`/`apiFetch`/`autoLogin`/`boot`/`toast` are self-contained per page), then
  build: a **Seasons list** (state badge, dates, countdown, **Activate** / **Restart**
  (`confirm()` first — it wipes tester progress) / **Save**); a **"New season"** form; an
  expandable **25-row tier editor** (`Tier | Free reward | Founder reward`, per-row Save →
  `PUT /api/admin/seasons/{id}/tiers/{tier}/{track}`); a **Founder Pass** panel (email + Grant
  / Revoke).
- **Nav link** — add `<a href="seasons.html">🎫 Season</a>` to the `.nav-links` block in
  `index.html`, `map.html`, `level-unlocks.html`, `rank-thresholds.html`, `encounters.html`
  (no shared nav component).

---

## Mobile — `mobile/lib/features/season/`

Skeleton copied from `features/titles/` (single overlay screen + service + `AsyncNotifier` +
widgets):

```
features/season/
  season_track_screen.dart      // full two-lane track; final VoidCallback? onClose
  buy_founder_pass_screen.dart  // Founder Pass buy page — Navigator.push target
  models/season_models.dart     // SeasonTrack, SeasonTier, SeasonRewardView, SeasonRewardState, SeasonClaimResult
  services/season_service.dart  // GET /season, POST /season/claim, POST /season/pass/purchase (+ exceptions)
  providers/season_provider.dart// seasonServiceProvider + SeasonNotifier(AsyncNotifier) w/ optimistic claim + refresh()
  widgets/
    season_tier_row.dart        // grid: free slot | rail(tier badge) | founder slot
    season_reward_slot.dart     // 4 states received/locked/pending/ready
    season_legend.dart
    season_milestone_card.dart
    season_theme.dart           // per-season accent (ember S1 / teal S2); pending=orange, ready=green universal
```

Palette from `core/constants/app_colors.dart`; reward art via `AppIconImage` / `ItemIconImage`
against `AppIcons` keys.

- **`season_track_screen.dart`** — `ConsumerWidget` → `Scaffold` → `Column`: header (back →
  `onClose`, "SEASON 1 / Trail of Embers", "Ends in 12d 04h"), tier-XP bar, an **"Unlock the
  Founder lane"** button (hidden once `hasFounderPass`) →
  `Navigator.push(BuyFounderPassScreen())`, `Free / Founder` lane header, then
  `Expanded(track.when(...))` of `SeasonTierRow`s + `SeasonLegend` + `SeasonMilestoneCard`. Tap
  a `ready` slot → `SeasonNotifier.claim(tier, track)` (optimistic → `received`) →
  `POST /season/claim` → `showChestOpenedOverlay`-style celebration
  (`core/widgets/chest_opened_overlay.dart` template) →
  `ref.invalidate(characterProfileProvider)` → `LevelUpNotifier.notify` if `leveledUp` →
  rollback + `AppToast.error` on locked/already-claimed.
- **`buy_founder_pass_screen.dart`** — pushed page: season art header, "Founder Pass" headline
  + price line, a scrollable "What you get" list (all Founder-track rewards + milestone pulled
  out), a Free-vs-Founder compare strip, a sticky blue→purple "Unlock the Founder Pass" CTA
  (`HomeLogWorkoutCta` style) → `SeasonNotifier.purchase()` → `POST /season/pass/purchase` →
  success → pop to the track (reached Founder tiles now `ready`). `// payment TODO`.
- **Home banner — DEFERRED.** `home_screen.dart` is not touched this iteration. Spec is
  `HomeSeason.dc.html`; when picked up it slots after `HomePortalCard` and reuses
  `seasonProvider`.
- **Shell wiring — `mobile/lib/core/shell/`** — follow the `titles` overlay pattern in
  `main_shell.dart`: `RingItem('season', '🎫', 'Season', Color(0xFFF5A623), iconAsset:
  AppIcons.ringSeason)` in `kAllRingItems`; `bool _seasonOpen`; `_onRingItemTap` branch;
  `build` Stack `Positioned.fill(bottom: kNavBarH, child: SeasonTrackScreen(onClose: …))`;
  clear `_seasonOpen` wherever other overlay bools clear; `_handleDeepLink` `case 'season'`
  (`lifelevel://season`); `_screenFor` `case 'season'`. Add `seasonProvider` to
  `core/session/invalidate_user_providers.dart`; add `AppIcons.ringSeason` (+ asset).

---

## Files

### Add — backend
- `backend/src/modules/LifeLevel.Modules.Seasons/**` — `.csproj` (copy Quest's), `Domain/Entities/{Season,SeasonRewardTier,UserSeasonProgress,UserSeasonClaim,UserFounderPass}.cs`, `Domain/Enums/{SeasonState,SeasonTrack,SeasonRewardType,FounderPassSource}.cs`, `Domain/{SeasonXpRules,SeasonOneCatalog}.cs`, `Application/UseCases/SeasonService.cs`, `Application/EventHandlers/{ActivityLogged,QuestCompleted,BossDefeated}SeasonXpHandler.cs`, `Application/DTOs/SeasonDtos.cs`, `Infrastructure/SeasonsModule.cs`, `Infrastructure/Persistence/Configurations/*Configuration.cs`.
- `backend/src/modules/LifeLevel.SharedKernel/Ports/{IItemRewardGrantPort,ISeasonRolloverPort}.cs`
- `backend/src/modules/LifeLevel.Modules.Items/Application/Ports/ItemRewardGrantPortAdapter.cs`
- `backend/src/LifeLevel.Api/Controllers/SeasonController.cs`
- `backend/src/LifeLevel.Api/Controllers/Admin/AdminSeasonsController.cs`
- `backend/src/LifeLevel.Api/Application/BackgroundJobs/SeasonRolloverJob.cs`
- `backend/src/LifeLevel.Api/Infrastructure/Persistence/SeasonSeeder.cs`
- `backend/src/LifeLevel.Api/Migrations/*_AddSeasonsModule.cs` (generated)
- `backend/src/LifeLevel.Api/wwwroot/admin/seasons.html`

### Modify — backend
- `LifeLevel.Api.csproj` — `<ProjectReference>` to the new module.
- `AppDbContext.cs` — 4 `DbSet`s, `ApplyConfigurationsFromAssembly`, cross-module `→ User` FKs, `using`s.
- `Program.cs` — `using`, `AddSeasonsModule()`, `AddHostedService<SeasonRolloverJob>()`, `AddScoped<SeasonSeeder>()` + invoke in startup scope.
- `LifeLevel.Modules.Items/Infrastructure/ItemsModule.cs` — register `IItemRewardGrantPort`.
- `wwwroot/admin/{index,map,level-unlocks,rank-thresholds,encounters}.html` — one nav `<a>` each.
- `backend/LifeLevel.slnx` — add the project (optional).

### Add — mobile
- `mobile/lib/features/season/**` (tree above).

### Modify — mobile
- `core/shell/main_shell.dart` — `_seasonOpen` overlay wiring (mirror `titles`).
- `core/shell/shell_models.dart` — `kAllRingItems` (+ maybe `kAllNavItems`).
- `core/constants/app_icons.dart` — `AppIcons.ringSeason` + asset entry.
- `core/session/invalidate_user_providers.dart` — `seasonProvider`.
- `mobile/pubspec.yaml` `assets:` — the season ring icon if a new file is added.

*(`home_screen.dart` is deliberately NOT modified — Home banner deferred.)*

---

## Verification

1. **Migration + seed** — start the API; `SeasonSeeder` inserts Season 1 + 50 tier rows.
   `GET /api/season` → `state Active`, `currentTier 0`, `endsAt ≈ now+56d`,
   `hasFounderPass false`, `tiers[0].free.state == "pending"`.
2. **Season XP (flat)** — log `running, 30 min, 5 km` → Season XP `+= 120+60+30 = 210`;
   complete a quest → `+40`; force a boss defeat → `+300`. `currentTier = SeasonXp / 600`.
3. **Claim gating** — `claim {tier:1, track:"Free"}` before reaching tier 1 → 409; after 600
   Season XP → 200 with the reward really applied (cross-check `GET /api/character/me` +
   inventory/titles); repeat → 409; `{track:"Founder"}` without the pass → 403.
4. **Founder Pass** — `POST /api/season/pass/purchase` → `hasFounderPass true`, reached Founder
   tiles flip `locked → ready`, claim one → granted. Admin `pass/grant` grants by email.
5. **Restart (admin)** — from `wwwroot/admin/seasons.html` hit **Restart** → `EndsAt` resets,
   every prior tester's `currentTier 0`, no claims, no Founder pass.
6. **Rollover + auto-grant** — set `EndsAt` to `now-1m`; within 10 min the job auto-claims
   every reached-but-unclaimed Free tile (+ Founder for pass holders),
   `UserSeasonClaim.WasAutoGranted == true`, `season.State == Ended`; a `Scheduled` season
   with `StartsAt <= now` becomes `Active`.
7. **Mobile** — `flutter run -d web-server --web-port 5000`. Open the radial ring → a new
   "Season" item → Season Track overlay (Home feed unchanged). `ready` tile tap → claim
   celebration + XP + level-up overlay when crossing a level. "Unlock the Founder lane" → buy
   page → unlock → reached Founder tiles claimable. `lifelevel://season` deep link opens it
   too. Kill/resume → `seasonProvider` refreshes.
8. **Second season** — admin creates Season 2 "Tide Reckoning" (`theme "tide"`), sets S1
   `EndsAt` past, rollover runs → S2 `Active`, mobile accent swaps ember → teal while
   `pending`/`ready` stay orange/green.

## Out of scope (this iteration)

- **Home-screen season banner / any Home entry point** — deferred. `home_screen.dart` is not
  touched; `HomeSeason.dc.html` is the spec for when it's picked up. Discovery is the radial
  ring + deep link only.
- Real payment / IAP receipt validation (the `purchase` endpoint just grants the entitlement).
- Cosmetic reward *backing* systems — trail effects / auras / frames / mounts are
  claim-recorded display placeholders until an equip system exists.
- Season leaderboard (the old `seasonal-events.html` mockup's event leaderboard).
- Season-specific quests (decision was flat Season-XP values, not a quest subsystem).
- Push notifications for "tier ready" / "season ending" / "season started" — easy follow-up
  via `INotificationPort` + a handler.

## Related
- [[Seasonal Events]] — the older 5-stage themed-challenge design this supersedes
- [[XP and Leveling]] · [[Login Rewards]] · [[Quest System]] · [[Items and Equipment]]
- [[Plan - Power Score System]]
