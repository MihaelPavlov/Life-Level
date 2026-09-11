# Talents (Gacha Talent Cards) — Design & Implementation Plan

> **Status: BUILT & verified against local :5128 (2026-09-07).**
> Backend module `LifeLevel.Modules.Talents` (16-talent catalog, wallet, draw/upgrade, event-driven currency), SharedKernel ports `ITalentBonusReadPort` / `ITalentProfileReadPort` / `ITalentStreakAssistPort`, migration `AddTalentsModule`, cross-module hooks in Activity/Encounters/Guild/Items/Quest/Streak/CharacterController, admin `talents.html`, and the mobile `features/talents/` overlay + shell wiring + profile "Talent bonuses" block are all in place. Verified: draw debits 1 token + 300 coins, dupes give shards, upgrade gates on shards/coins (409), `Focused Training` Lv.5 made a 90-XP gym workout award 97 (×1.04 gear ×1.05 talent), `/character/me` returns the `talents` summary. DI cycle (TalentService↔StreakService via shield port) was broken by moving the Shield Craft grant to `TalentsController`.

---


## Context

Life-Level has **no talent / perk / skill / passive-bonus system and no in-game currency** — a
repo-wide grep confirms it's fully greenfield. The one shipped "passive bonus" mechanic is
equipped-item gear bonuses (`IGearBonusReadPort` → `GearBonuses(XpBonusPct, StrBonus, …)`,
summed by `ItemService`, applied in `ActivityService.LogActivityAsync`). That is the pattern a
talent system copies.

The UI is already designed: artifact `63d23408-559f-4a6a-a6bc-6f6cdce93120`
(`design-mockup/canvas-command-center/Talents.dc.html`). It shows a **gacha "Draw Talent Card"
screen**: a grid of hex talent tiles (icon + name + `Lv.1`–`Lv.10`, a green "upgradeable" badge,
dimmed = not owned), a 3-currency bar, a **Draw Talent Card** button costing currency, and a
featured-talent overlay with effect text (`"Steel Resolve · Lv.3 · At session start, gain a
shield worth +15% XP"`).

There is also an older design doc `docs/obsidian/02 - Game Design/Plan - Adaptive Skill Tree.md`
(behavior-unlocked branches, anti-"+3% filler"). **We are not building that** — the user chose
the gacha talent-card system from the mockup.

### Decisions locked with the user

| Question | Decision |
|---|---|
| Direction | **Gacha talent cards** (the mockup). Flat/universal catalog, no class branches. |
| Activation | **All owned talents always active** — every owned talent contributes its bonus permanently. No loadout slots. |
| Draw / upgrade model | **Hybrid** — a random draw yields a new talent *or* duplicate **shards**; the player then spends that talent's **shards + coins** to level a specific owned talent (the per-tile "upgrade" badge). |
| Effect types in v1 | **All four**: stat bonuses, XP multipliers, streak/shield perks, boss-damage + reward/drop bonuses. |

### Proposed defaults (tunable, admin-editable — not blocking)

- **Two wallet currencies** + per-talent shards: **Talent Coins** (soft, earned from every
  activity/quest/boss), **Talent Tokens** (hard, earned on level-up / rank-up / milestones),
  and **Shards** (a count on each `UserTalent` row, from duplicate draws). The mockup's 3-pill
  bar renders **Coins · Tokens · Talents owned (X/N)**. ("Aura stones" from the mockup art are
  not a separate currency in v1.)
- **Draw cost** `1 Token + 300 Coins`. Result: while un-owned talents remain, ~60 % a new
  talent (weighted by `DrawWeight`), ~40 % shards of a random owned talent (5–15 by rarity);
  once everything is owned, 100 % shards.
- **Upgrade cost** Lv `k → k+1`: `Shards = 5 + 3k`, `Coins = 100k` (rarity-scaled).
- **Rarity** (`Common | Rare | Epic`) affects per-level value, draw weight and upgrade cost;
  every talent still maxes at **Lv.10**.
- Talent stat bonuses are an **effective overlay** on the profile (exactly like gear), never
  added to the clamped 0–100 base `Character.Strength…`.
- Talents apply to **imported/external activities** too (add the bonus block to
  `LogExternalActivityAsync`, which today skips even the gear bonus).
- Surface = **shell overlay from a radial-ring item + `lifelevel://talents` deep link**, mirroring
  `titles` / `season`. Not a 5th bottom-nav tab.

---

## Talent catalog — v1 (16 talents)

Each scales linearly Lv.1→Lv.10. "Hook" = the exact code site the effect is read.

| # | Key / Name | Group | Effect @ Lv.10 (per-level) | Hook |
|---|---|---|---|---|
| 1 | `iron-grip` **Iron Grip** | Stat | +10 STR (+1) overlay | profile enrichment + `ActivityService` stat overlay |
| 2 | `deep-lungs` **Deep Lungs** | Stat | +10 END (+1) | same |
| 3 | `fast-twitch` **Fast Twitch** | Stat | +10 AGI (+1) | same |
| 4 | `loose-joints` **Loose Joints** | Stat | +10 FLX (+1) | same |
| 5 | `second-engine` **Second Engine** | Stat | +10 STA (+1) | same |
| 6 | `focused-training` **Focused Training** | XP | +10 % activity XP (+1 %) | `ActivityService.LogActivityAsync` after gear block |
| 7 | `morning-momentum` **Morning Momentum** | XP | first activity of the UTC day +25 % XP (+2.5 %) | `ActivityService` (needs "first today" check vs `LastActivityDate`) |
| 8 | `runners-high` **Runner's High** | XP | Running/Cycling/Swimming/Hiking +10 % XP (+1 %) | `ActivityService` (per-type) |
| 9 | `iron-discipline` **Iron Discipline** | XP | Gym/Climbing/Yoga +10 % XP (+1 %) | `ActivityService` (per-type) |
| 10 | `quest-zeal` **Quest Zeal** | XP | quest reward XP +20 % (+2 %) | `QuestService` — wrap `AwardXpAsync` at `:179` & all-5 bonus at `:215` |
| 11 | `second-wind` **Second Wind** | Streak | auto-recover a 2-day gap with 0 shields, up to `level/2` times/week | `StreakService.RecordActivityDayAsync:63-72` |
| 12 | `steel-resolve` **Steel Resolve** | Streak | first activity within 24 h of a broken streak +50 % XP (+5 %) | `ActivityService` + a `LastStreakBrokenAt` flag written by a `StreakBrokenEvent` handler |
| 13 | `shield-craft` **Shield Craft** | Streak | +1 streak shield granted once per level reached | on level-up in `TalentService` via `IStreakShieldPort.AddShieldAsync` |
| 14 | `direct-hit` **Direct Hit** | Boss | +20 % boss damage (+2 %) | `ActivityBossDamageAdapter.cs:43` **and** `GuildService.ApplyActivityAsync:564` |
| 15 | `boss-instinct` **Boss Instinct** | Boss | activity while a boss/raid is active: extra +20 % boss damage (+2 %) | same two sites (conditional on active boss) |
| 16 | `fair-exchange` **Fair Exchange** | Reward | +10 % item drop chance (+1, additive to `DropChancePct`) | `ItemGrantService.EvaluateTriggerAsync:75,123` |

`TalentCatalog` (static) holds these as `TalentDef` records; a `TalentSeeder` inserts them
idempotently; admin can edit every field before go-live. Adding talents later = a catalog entry
+ (if a new `EffectType`) one new hook.

---

## How talents are used (the loop)

1. **Earn currency** — a `LifeLevel.Modules.Talents` event handler on `ActivityLoggedEvent`
   (+`QuestCompletedEvent`, `BossDefeatedEvent`, `CharacterLeveledUpEvent`, `CharacterRankChangedEvent`)
   credits `UserTalentWallet` (Coins from activity/quest/boss; Tokens on level-up/rank-up).
   Mirrors `SeasonXpActivityHandler` etc.
2. **Draw** — `POST /api/talents/draw` spends `1 Token + 300 Coins`, rolls server-side:
   new weighted talent → `UserTalent{Level=1}`, or shards → `UserTalent.Shards += n`. Returns a
   `TalentDrawResult` (kind, talent view, shards) the client reveals.
3. **Upgrade** — `POST /api/talents/{key}/upgrade` spends that talent's `Shards + Coins`,
   `Level++` up to `MaxLevel`. This is the per-tile badge.
4. **Always-active aggregation** — `TalentService` implements
   `ITalentBonusReadPort.GetBonusesAsync(userId) → TalentBonuses` (a record: `XpPct`,
   `CardioXpPct`, `StrengthStyleXpPct`, `MorningXpPct`, `ComebackXpPct`, `QuestXpPct`,
   `StrBonus…StaBonus`, `BossDamagePct`, `BossActiveDamagePct`, `DropChanceBonus`, plus
   `SecondWindChargesPerWeek`). Computed by summing owned `UserTalent` rows through
   `TalentCatalog`. Consumed at the hook sites in the table.
5. **Display** — the Talents screen (grid + featured detail + currency bar + draw button);
   `GET /api/character/me` is enriched with a `TalentSummary` (owned count, total levels, the
   effective-bonus lines) via a new `ITalentProfileReadPort`, shown next to gear bonuses.

---

## Backend — `LifeLevel.Modules.Talents`

New class library, structured like `LifeLevel.Modules.Seasons`
(`backend/ARCHITECTURE.txt` "INTERNAL LAYOUT OF EVERY MODULE"). References only
`LifeLevel.SharedKernel` + EF Core. One shared `AppDbContext`, migrations in
`LifeLevel.Api/Migrations`.

### Entities (`Domain/Entities/`)

- **`Talent`** — catalog row: `Id`, `Key` (slug), `Name`, `Description`, `IconKey`,
  `Rarity` (`TalentRarity` enum), `EffectType` (`TalentEffectType` enum — `StatStr/StatEnd/…`,
  `ActivityXpPct`, `CardioXpPct`, `StrengthStyleXpPct`, `MorningXpPct`, `ComebackXpPct`,
  `QuestXpPct`, `BossDamagePct`, `BossActiveDamagePct`, `DropChancePct`, `SecondWind`,
  `ShieldPerLevel`), `PerLevelValue` (double), `MaxLevel` (int, default 10), `DrawWeight` (int),
  `SortOrder`, `IsActive`. Seeded, admin-editable.
- **`UserTalent`** — `Id`, `UserId` (FK→User, cascade), `TalentId` (FK→Talent), `Level` (1..Max),
  `Shards` (int, unspent), `UnlockedAt`, `UpdatedAt`. Unique `(UserId, TalentId)`. Presence = owned.
- **`UserTalentWallet`** — `Id`, `UserId` (FK→User, unique), `Coins` (long), `Tokens` (int),
  `LastStreakBrokenAt` (DateTime?, for Steel Resolve), `UpdatedAt`. Lazy-created.
- **`TalentDrawEntry`** *(optional, v1-nice)* — `Id`, `UserId`, `DrawnAt`, `Kind`
  (`NewTalent | Shards`), `TalentId`, `ShardsAwarded`. Audit / future pity.

EF config: one `TalentConfigurations.cs` with per-entity `IEntityTypeConfiguration<T>` (enums
`.HasConversion<string>()`, unique indexes), matching `SeasonConfigurations.cs`. Cross-module
`→ User` FKs added inline in `AppDbContext.OnModelCreating` next to the `Season → User` block.
Add the DbSets + `ApplyConfigurationsFromAssembly(typeof(TalentsModule).Assembly)`.

### `Domain/TalentCatalog.cs`

Static `TalentDef[]` — the 16 rows above. Also `Domain/TalentEconomy.cs` (pure static): draw
cost, per-rarity shard payout, upgrade cost curve, currency earn rates. Single source of truth,
mirrors `SeasonXpRules.cs` / `SeasonOneCatalog.cs`.

### `Application/UseCases/TalentService.cs`

Ctor deps (all existing owners, no DI cycle): `DbContext db`, `IStreakShieldPort shields`
(Shield Craft grants), `ICharacterLevelReadPort levels` (level-up token grant). Implements:

- **`ITalentBonusReadPort.GetBonusesAsync(userId) → TalentBonuses`** — the aggregate consumed by
  Activity/Boss/Guild/Items/Quest/Streak.
- **`ITalentProfileReadPort.GetSummaryAsync(userId) → TalentSummaryDto`** — for `/character/me`.
- **`GetScreenAsync(userId) → TalentScreenResponse`** — full read model for the mobile screen
  (wallet, every catalog talent with `owned/level/shards/canUpgrade/upgradeCost/effectText`,
  featured effect strings). Server computes all state; client renders dumbly (Seasons pattern).
- **`DrawAsync(userId) → TalentDrawResult`** — validates wallet, debits, rolls, persists,
  returns the reveal payload. Throws `InvalidOperationException` (→409) on insufficient funds.
- **`UpgradeAsync(userId, key) → TalentUpgradeResult`** — validates shards+coins & `< MaxLevel`,
  debits, `Level++`, on the way runs Shield Craft's per-level grant. Throws
  `InvalidOperationException` (→409).
- **Currency credit helpers** called by the event handlers.

Controller error mapping copies `SeasonController` (`InvalidOperationException`→409,
`UnauthorizedAccessException`→403, bad input→400 `{error}`).

### Event handlers (`Application/EventHandlers/`)

`TalentCurrency{Activity,Quest,Boss,LevelUp,RankUp}Handler` — `IEventHandler<…>` each, crediting
the wallet via `TalentService`. `TalentStreakBrokenHandler : IEventHandler<StreakBrokenEvent>`
writes `UserTalentWallet.LastStreakBrokenAt` (feeds Steel Resolve). Registered in
`AddTalentsModule()` exactly like `SeasonsModule`.

### Ports — new in `backend/src/modules/LifeLevel.SharedKernel/Ports/`

- **`ITalentBonusReadPort`** + `record TalentBonuses(...)` — the aggregate.
- **`ITalentProfileReadPort`** + `record TalentSummaryDto(...)` — profile enrichment.

Both implemented by `TalentService`; aliased in `AddTalentsModule()`
(`services.AddScoped<ITalentBonusReadPort>(sp => sp.GetRequiredService<TalentService>())`).

### DTOs (`Application/DTOs/TalentDtos.cs`)

`TalentScreenResponse`, `TalentView` (+ `TalentTileState` enum `Locked | Owned | Upgradeable`),
`TalentWalletView`, `TalentDrawResult` (`Kind`, `TalentView`, `int Shards`, `bool IsNew`),
`TalentUpgradeResult` (`TalentView`, `int NewLevel`, `string EffectText`).

### API (`backend/src/LifeLevel.Api/Controllers/`)

**`TalentsController.cs`** — `[Route("api/talents")] [Authorize]`, injects `TalentService` +
`IUserContext`:
- `GET  /api/talents` → `TalentScreenResponse`
- `POST /api/talents/draw` → `TalentDrawResult`
- `POST /api/talents/{key}/upgrade` → `TalentUpgradeResult`

**`Controllers/Admin/AdminTalentsController.cs`** — `[Route("api/admin/talents")]
[Authorize(Policy="Admin")]`, injects `AppDbContext` (template `AdminSeasonsController.cs` /
`AdminItemsController.cs`):
- `GET /api/admin/talents` — list catalog + a summary of holders.
- `POST /api/admin/talents` / `PUT /api/admin/talents/{id:guid}` / `DELETE …` — catalog CRUD.
- `POST /api/admin/talents/grant` `{ userIdOrEmail, coins?, tokens?, talentKey?, shards? }` —
  tester top-ups.
- `POST /api/admin/talents/reset` `{ userIdOrEmail }` — wipe a tester's `UserTalent` +
  wallet for retest.

### DI, seeder, migration

- **`Infrastructure/TalentsModule.cs`** `AddTalentsModule()` — scoped `TalentService` + the two
  port aliases + the six event handlers. Add `using` + `builder.Services.AddTalentsModule();` to
  `Program.cs` (module block, after Character/Streak/Items/Quest so their ports exist).
- **`LifeLevel.Api/Infrastructure/Persistence/TalentSeeder.cs`** — `if (await
  db.Set<Talent>().AnyAsync()) return;` then `db.AddRange(TalentCatalog.Build())`. Register
  `AddScoped<TalentSeeder>()` (`Program.cs:158`) + invoke in the startup scope (`Program.cs:265`).
- Migration: `dotnet ef migrations add AddTalentsModule --project src/LifeLevel.Api
  --startup-project src/LifeLevel.Api` (auto-applied via `db.Database.MigrateAsync()`).
- `LifeLevel.Api.csproj` — `<ProjectReference>` to the module. `AppDbContext.cs` — DbSets +
  `ApplyConfigurationsFromAssembly` + `→ User` FKs.

---

## Cross-module hook edits (the main cross-cutting change)

Each consuming service gets `ITalentBonusReadPort` injected into its primary constructor and
reads `TalentBonuses` once per operation. All edits are small and mirror the existing
gear-bonus block.

| File | Edit |
|---|---|
| `backend/src/modules/LifeLevel.Modules.Activity/Application/UseCases/ActivityService.cs` | After the gear XP block (`:55-63`): apply `XpPct` + per-type (`CardioXpPct`/`StrengthStyleXpPct`) + `MorningXpPct` (first activity today) + `ComebackXpPct` (within 24 h of `LastStreakBrokenAt`). Build a talent stat overlay and pass to the profile (do **not** feed `ApplyStatGainsAsync`). Replicate the whole block in `LogExternalActivityAsync` (also add the missing gear bonus there). |
| `backend/src/modules/LifeLevel.Modules.Adventure.Encounters/Infrastructure/ActivityBossDamageAdapter.cs` (`:43`) | `damage = (int)(damage * (1 + (BossDamagePct + activeBossBonus)/100.0))`. |
| `backend/src/modules/LifeLevel.Modules.Guild/Application/UseCases/GuildService.cs` (`ApplyActivityAsync:564`) | Same multiplier on the guild-raid `damage`. |
| `backend/src/modules/LifeLevel.Modules.Items/Application/UseCases/ItemGrantService.cs` (`:75`, `:123`) | `effectiveChance = rule.DropChancePct + bonuses.DropChanceBonus` before the `rng.Next(100)` compare. |
| `backend/src/modules/LifeLevel.Modules.Quest/Application/UseCases/QuestService.cs` (`:179`, `:215`) | Scale `quest.RewardXp` and the flat `300` all-5 bonus by `(1 + QuestXpPct/100)`. |
| `backend/src/modules/LifeLevel.Modules.Streak/Application/UseCases/StreakService.cs` (`RecordActivityDayAsync:63-72`) | Second Wind: when a 2-day gap and `ShieldsAvailable == 0`, allow recovery up to `SecondWindChargesPerWeek` times (track a weekly counter on `Streak` or `UserTalentWallet`). |
| `backend/src/LifeLevel.Api/Controllers/CharacterController.cs` (`GetProfile`) | Inject `ITalentProfileReadPort`; `profile with { Talents = await talentProfile.GetSummaryAsync(userId) }`, exactly like `GearBonuses`. Add `TalentSummaryDto? Talents = null` to `CharacterProfileResponse`. |

DI-cycle check: none of Activity/Encounters/Guild/Items/Quest/Streak/Character is referenced by
the Talents module, so injecting `ITalentBonusReadPort` (owned by SharedKernel, implemented in
Talents) is safe.

---

## Admin web UI

- **New `backend/src/LifeLevel.Api/wwwroot/admin/talents.html`** — copy `seasons.html`
  (self-contained `getToken`/`apiFetch`/`autoLogin`/`boot`/`toast` block, `:root` theme). Build:
  a **catalog table** (key, name, rarity, effect type + per-level value, max level, draw weight,
  active) with per-row Save/Delete + an "Add talent" form; a **grant/reset** mini-panel
  (email + coins/tokens/talent/shards). Points at `api/admin/talents`.
- **Nav link** — add `<a href="talents.html">🌟 Talents</a>` to the `.nav-links` block in
  `index.html`, `map.html`, `level-unlocks.html`, `rank-thresholds.html`, `encounters.html`,
  `seasons.html` (no shared nav component).

---

## Mobile — `mobile/lib/features/talents/`

Skeleton copied from `features/season/`:

```
features/talents/
  talents_screen.dart            // ConsumerWidget, final VoidCallback? onClose
  models/talent_models.dart      // TalentScreen, TalentView, TalentTileState, TalentWallet,
                                 // TalentDrawResult, TalentUpgradeResult  (hand fromJson, Seasons idiom)
  services/talents_service.dart   // GET /talents, POST /talents/draw, POST /talents/{key}/upgrade
                                 // + TalentException / TalentInsufficientFundsException (409)  — copy season_service.dart
  providers/talents_provider.dart // talentsServiceProvider + TalentsNotifier(AsyncNotifier<TalentScreen>)
                                 // draw()/upgrade() with optimistic update + rollback (titles_provider.dart pattern), refresh()
  widgets/
    talent_currency_bar.dart     // 3 pills: Coins · Tokens · Owned X/N  (adapt _StatChipsRow from item_obtained_overlay.dart)
    talent_grid.dart             // GridView.builder, 4 cols  (structure from profile/tabs/inventory_tab.dart)
    talent_tile.dart             // rounded-hex tile: icon + name + Lv badge + green "upgrade" dot; dim when not owned
                                 //   (rounded-square/hex — no hex geometry exists; CustomClipper<Path> if a true hex is wanted)
    talent_detail_panel.dart     // featured talent: big icon, name, Lv, effect text, "Upgrade (n shards + n coins)" button
    talent_draw_button.dart      // "Draw Talent Card" gradient CTA with cost pills
    talent_theme.dart            // rarity → colour; talentIconAsset(key) prefix resolver (season_theme.dart pattern)
  widgets/talent_draw_overlay.dart // showTalentDrawnOverlay(context, result): showGeneralDialog + fade/slide/scale +
                                 //   pulsing glow, rarity-tinted — copy item_obtained_overlay.dart
```

- `talents_screen.dart` = `Scaffold(AppColors.background)` → `SafeArea` → header (back →
  `onClose ?? Navigator.pop`, "TALENTS") → `ref.watch(talentsProvider).when(loading/error/data)`
  → currency bar, `talent_grid`, `talent_detail_panel` for the selected tile, `talent_draw_button`.
- Draw: `await ref.read(talentsProvider.notifier).draw()` → `showTalentDrawnOverlay(...)` →
  `ref.invalidate(characterProfileProvider)`. Insufficient funds → `AppToast.error`.
- Upgrade: optimistic tile bump + rollback on `TalentException`.
- New icons: `core/constants/talent_icons.dart` (`talentIconAsset({key,name})`, prefix-based) +
  a `TalentIconImage` mirroring `ItemIconImage` (asset-or-emoji fallback). Art in
  `mobile/assets/Talents/` → add `- assets/Talents/` to `pubspec.yaml`.
- Profile: add `talentSummary` to `mobile/lib/features/character/models/character_profile.dart`
  (mirrors `gearBonuses`); render a "Talent bonuses" block in `profile_overview_tab.dart` next
  to the gear block. `profile_stat_metadata.dart` `perks` (static flavor) is untouched.

### Shell wiring — `mobile/lib/core/shell/` (mirror `_seasonOpen`, ~11 sites)

1. `shell_models.dart` — `RingItem('talents', '🌟', 'Talents', Color(0xFF38d9c8), iconAsset: AppIcons.ringTalents)` in `kAllRingItems`; optionally swap into `kDefaultRingIds`.
2. `main_shell.dart` — `import '../../features/talents/talents_screen.dart';`; `bool _talentsOpen = false;`; add `_talentsOpen = false;` to every place the other overlay bools are cleared (`_onTutorialStateChanged`, `_navTabSub` ×2, `_worldMapSub`, `_bossOverlaySub`, `ShellNavBar.onTap` ×2, `_onRingItemTap` other branches, every `_handleDeepLink` case); new `_onRingItemTap` branch `if (id == 'talents') {…_talentsOpen = true;…}`; new `_handleDeepLink` `case 'talents':`; `_screenFor` `case 'talents': return const TalentsScreen();`; `build` Stack `if (_talentsOpen) Positioned.fill(bottom: kNavBarH, child: TalentsScreen(onClose: …))`.
3. `core/session/invalidate_user_providers.dart` — `ref.invalidate(talentsProvider)` + `container.invalidate(talentsProvider)` in **both** functions.
4. `core/constants/app_icons.dart` — `static const String ringTalents = 'assets/icons/ring_talents.png';` + drop the PNG in `mobile/assets/icons/`.

---

## Files

### Add — backend
- `backend/src/modules/LifeLevel.Modules.Talents/**` — `.csproj` (copy `LifeLevel.Modules.Seasons.csproj`),
  `Domain/Entities/{Talent,UserTalent,UserTalentWallet,TalentDrawEntry}.cs`,
  `Domain/Enums/{TalentRarity,TalentEffectType,TalentDrawKind}.cs`,
  `Domain/{TalentCatalog,TalentEconomy}.cs`,
  `Application/UseCases/TalentService.cs`,
  `Application/EventHandlers/TalentCurrency{Activity,Quest,Boss,LevelUp,RankUp}Handler.cs`, `TalentStreakBrokenHandler.cs`,
  `Application/DTOs/TalentDtos.cs`,
  `Infrastructure/TalentsModule.cs`, `Infrastructure/Persistence/Configurations/TalentConfigurations.cs`.
- `backend/src/modules/LifeLevel.SharedKernel/Ports/{ITalentBonusReadPort,ITalentProfileReadPort}.cs`
- `backend/src/LifeLevel.Api/Controllers/TalentsController.cs`
- `backend/src/LifeLevel.Api/Controllers/Admin/AdminTalentsController.cs`
- `backend/src/LifeLevel.Api/Infrastructure/Persistence/TalentSeeder.cs`
- `backend/src/LifeLevel.Api/Migrations/*_AddTalentsModule.cs` (generated)
- `backend/src/LifeLevel.Api/wwwroot/admin/talents.html`

### Modify — backend
- `backend/src/LifeLevel.Api/LifeLevel.Api.csproj` — `<ProjectReference>`.
- `backend/src/LifeLevel.Api/Infrastructure/Persistence/AppDbContext.cs` — DbSets,
  `ApplyConfigurationsFromAssembly`, `→ User` FKs.
- `backend/src/LifeLevel.Api/Program.cs` — `AddTalentsModule()`, `AddScoped<TalentSeeder>()` + invoke.
- `backend/src/LifeLevel.Api/Controllers/CharacterController.cs` + `CharacterProfileResponse.cs` — talent summary enrichment.
- `ActivityService.cs`, `ActivityBossDamageAdapter.cs`, `GuildService.cs`, `ItemGrantService.cs`,
  `QuestService.cs`, `StreakService.cs` — the hook edits (table above); each also gets the port
  registered nowhere new (constructor injection resolves the SharedKernel interface).
- 6 × `wwwroot/admin/*.html` — one nav `<a>` each.

### Add — mobile
- `mobile/lib/features/talents/**` (tree above), `mobile/lib/core/constants/talent_icons.dart`,
  `mobile/lib/core/widgets/talent_icon_image.dart`, `mobile/assets/Talents/` + `assets/icons/ring_talents.png`.

### Modify — mobile
- `mobile/lib/core/shell/{main_shell,shell_models}.dart`, `core/session/invalidate_user_providers.dart`,
  `core/constants/app_icons.dart`, `pubspec.yaml` (`- assets/Talents/`),
  `features/character/models/character_profile.dart`, `features/profile/tabs/profile_overview_tab.dart`.

---

## Verification

1. **Migration + seed** — start the API (`:5128`). `AddTalentsModule` migration applies;
   `TalentSeeder` inserts 16 talents. `GET /api/talents` (test user) → wallet `Coins 0 /
   Tokens 0`, all 16 tiles `Locked`.
2. **Currency accrual** — log `running 30 min 5 km` → `GET /api/talents` shows Coins credited
   by `TalentEconomy` rate; complete a quest → more Coins; defeat a boss (`BossController`
   debug) → more; force a level-up → `Tokens += 1`.
3. **Draw** — `POST /api/talents/draw` with funds → 200 `TalentDrawResult` (new talent at
   Lv.1 **or** shards on an owned one); wallet debited `1 Token + 300 Coins`. Without funds → 409.
4. **Upgrade** — draw the same talent twice for shards, `POST /api/talents/{key}/upgrade` →
   `Level 1 → 2`, shards+coins debited; repeat past `MaxLevel` → 409.
5. **Bonuses actually apply** — own `Focused Training` Lv.5 → log an activity → awarded XP is
   `base × 1.05` (cross-check `GET /api/character/me` XP delta / `xpHistory`). Own `Iron Grip`
   Lv.10 → `/character/me` `strength` effective value / `talents` summary shows +10. Own
   `Direct Hit` Lv.10 with an active boss → damage per workout `× 1.20` (`GET /api/boss`).
   Own `Fair Exchange` → `ItemGrantService` roll uses the raised chance.
6. **Profile enrichment** — `GET /api/character/me` returns a `talents` block (owned count,
   total levels, effective bonus lines).
7. **Admin** — `wwwroot/admin/talents.html` (auto-login): edit a talent's `PerLevelValue`,
   Save, re-`GET /api/talents` reflects it; `grant` tops up a tester; `reset` wipes them.
8. **Mobile** — `flutter run -d web-server --web-port 5000
   --dart-define=API_BASE_URL=http://localhost:5128/api`. Radial ring → **Talents** →
   overlay opens from the shell. Currency bar shows Coins/Tokens/Owned. Draw → animated
   reveal → grid updates, `characterProfileProvider` refreshes. Tap an owned tile → detail
   panel + Upgrade button; upgrade → Lv bumps, effect text updates. `lifelevel://talents`
   deep link opens the overlay. Kill/resume → provider refreshes. Profile Overview shows the
   "Talent bonuses" block.

---

## Out of scope / open tuning (this iteration)

- **Class branches / adaptive skill tree** (`Plan - Adaptive Skill Tree.md`) — the catalog is
  flat; branch grouping is a later re-tag, not a rewrite.
- **"Aura stones" as a 3rd real currency**, pity timers, premium/paid draws, duplicate→dust
  economy — v1 uses Coins + Tokens + per-talent Shards only.
- **Talent respec / refund**, talent loadout slots — all owned talents are always active.
- Exact numbers (earn rates, draw odds, upgrade curve, per-level values, rarity split) are
  first-pass and fully admin-editable; balance pass after playtest.
- Push notification "talent ready to upgrade" — easy follow-up via `INotificationPort`.
- `Steel Resolve` needs the `LastStreakBrokenAt` flag + a `StreakBrokenEvent` handler; if that
  handler proves fiddly it can ship in v1.1 without blocking the other 15 talents.
