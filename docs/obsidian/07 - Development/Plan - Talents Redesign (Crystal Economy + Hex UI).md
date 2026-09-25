# Plan - Talents Redesign (Crystal Economy + Hex UI)

## Context

The Talents feature (gacha talent-card system) shipped with a functional but plain UI: a
4-column grid, a boxed detail panel below the grid, and a static "draw result" dialog with no
suspense. This pass restyles it to match reference mockups (hexagonal honeycomb tile grid,
icon-based currency display, inline detail text with paging arrows) and makes the draw feel
like a real gacha pull — tap once, watch a highlight sweep across the grid and land on the
result automatically.

## Progressive card-draw costs

Card draws now scale from the player's lifetime count of successful card draws. With `n` as
the number of completed draws, the server calculates Coins using
`roundTo5(300 + 67.999411685344n + 43.279658674746(1.015ⁿ - 1))` and Crystals using
`round(1 + 0.053924695724n + 5.539796310368(1.015ⁿ - 1))`. This gives a gentle early
increase, reaches 1,675 Coins + 4 Crystals after 20 draws, and accelerates to 8,675 Coins +
35 Crystals after 120 draws. Only the current price is visible in the UI. Draws stop when
every active talent reaches its configured maximum level.

It also introduces a new currency, **Talent Crystals**, deliberately scarce and tied to real
game-world progress rather than routine grinding:

- **Crystals replace Tokens entirely** as the currency spent on card draws (Tokens retired —
  nothing earns or spends them any more).
- **Crystals also replace per-talent Shards** as the currency spent on upgrades (Shards
  retired — duplicate draws now refund Coins + Crystals instead of granting Shards).
- Crystals are earned **only** from: beating a boss (regular or mini), completing a map
  region/zone, and claiming a reward (daily login reward, opening a chest — local-map or
  world-zone). Guild raid rewards are deferred to a later pass.
- Coins are unaffected — still earned broadly (activities, quests, level-ups, boss defeats),
  still spent on both draws and upgrades alongside Crystals.

## Backend changes

- `UserTalentWallet.Tokens` → `Crystals` (int); `UserTalent.Shards` removed;
  `TalentDrawEntry.ShardsAwarded` → `CrystalsAwarded`. EF migration
  `RenameTalentTokensToCrystals` (data-preserving rename + column drop).
- `TalentEconomy.cs`: removed `TokensPerLevelUp`, `TokensPerRankUp`, `ShardPayout`,
  `UpgradeShardCost`. Added `DrawCrystalCost=1` (was `DrawTokenCost`, `DrawCoinCost=300`
  unchanged), `UpgradeCrystalCost(rarity, level)` (`1 + level/3`, ×1.5 Rare / ×2 Epic),
  `DuplicateRefund(rarity)` (small Coins+Crystals refund on a duplicate draw),
  `CrystalsPerBossDefeat`/`PerZoneCompletion`/`PerRewardClaim` (small flat grants).
- New SharedKernel events: `ZoneCompletedEvent(UserId, ZoneId)`,
  `RewardClaimedEvent(UserId, Source)`. Published from `WorldZoneService.CompleteZoneAsync`
  (first-time zone completion), `LoginRewardService.ClaimDailyRewardAsync`,
  `ChestService.CollectAsync` (local map), `WorldChestService.OpenAsync` (world zone).
  `BossDefeatedEvent` reused as-is for the boss source.
- `TalentCurrencyHandlers.cs`: boss handler now also grants Crystals (keeps its Coins grant);
  new `TalentCurrencyZoneHandler`/`TalentCurrencyRewardHandler`; level-up handler drops its
  token grant (keeps coins); `TalentCurrencyRankUpHandler` removed entirely (its only job was
  the now-retired Tokens).
- `TalentService`/`TalentDtos`: `AddTokensAsync`→`AddCrystalsAsync`; `DrawAsync`/`UpgradeAsync`
  moved to Crystals + `DuplicateRefund`; `TalentWalletView`/`TalentView`/`TalentScreenResponse`/
  `TalentDrawResult` field renames to match.
- Follow-on: `ITalentProfileReadPort`/`TalentSummaryDto.Tokens` → `Crystals` (read by the
  Character profile endpoint, separate from `/talents`) — required for compilation, not
  originally listed but necessary. Mobile's `CharacterProfile.TalentSummary.tokens` was
  updated to `crystals` to match.
- Admin tooling (`AdminTalentsController`, `wwwroot/admin/talents.html`) updated to grant
  Coins/Crystals only (per-talent shard granting removed, concept no longer exists).

## Mobile changes (`mobile/lib/features/talents/`)

- Models/service: renamed fields to match the new backend contract exactly (camelCase JSON
  keys unchanged in shape, just the renames above).
- `_CurrencyBar`: Coins + Crystals icon pills (dropped Tokens pill), kept owned/catalog pill.
- `_TalentGrid` → hexagonal honeycomb layout (`_HexTalentTile`/`_HexagonClipper`/
  `_ConnectorDot`): pointy-top hex tiles via `ClipPath`, offset rows (4/3 alternating) so
  neighbours interlock, small connector dots between adjacent tiles. Kept per-tile visuals
  (rarity border, dimmed-when-locked, "Lv.N" badge, upgrade-arrow badge). Center decorative
  emblem from the reference mockup intentionally **not** built — no data to drive it
  meaningfully; per-tile name label also dropped from the tile face (still shown in the detail
  area) to keep row-packing tight.
- Detail area (`_DetailArea`) replaces the old boxed `_DetailPanel`: inline, no border, `‹ Name
  ›` paging row (wraps at the ends), rarity/level line, one-sentence effect/description, and
  (if owned + not maxed) coin+crystal icon-chip upgrade cost with the upgrade button.
- `_DrawButton` renamed to "Card Draw", cost sentence replaced with coin+crystal icon chips.
- Roulette draw (`talent_draw_overlay.dart`'s `showTalentDrawSequence`): server draw result
  fetched first (server stays authoritative for RNG), then an `AnimationController`-driven
  highlight sweeps across the grid's tile order (several loops + deceleration) and lands on the
  actual result, followed by a brief simplified reveal popup (name, new-vs-duplicate, effect)
  that auto-dismisses.
- New `talent_info_sheet.dart`: rarity legend + draw-odds/duplicate-refund explanation +
  Crystal-sourcing rules (bosses, map regions, rewards — not routine activity), opened via a
  new info button in the header.

## Verification performed

- `dotnet build` — 0 errors; migration applied cleanly (`dotnet ef database update`);
  `dotnet test` — 190 passed.
- `flutter analyze` — 0 new errors (298 pre-existing unrelated lint infos elsewhere).
- Live end-to-end via `curl` against a running dev backend: confirmed `GET /api/talents`
  returns the new `crystals`/`upgradeCrystalCost`/`drawCrystalCost` shape with no leftover
  `tokens`/`shards`; exercised `POST /talents/draw` (new-talent draw, correct Coins+Crystals
  deduction) and `POST /talents/{key}/upgrade` (correct Coins+Crystals deduction, level bump,
  updated `effectText`).
- Live UI via Playwright against `flutter run -d web-server`: confirmed the honeycomb grid
  renders with correct rarity-colored borders and owned/locked states, the inline detail area
  pages correctly between talents (including switching between owned/not-owned copy), the
  "Card Draw" button shows icon-only costs, and the info modal opens with the expected copy.
  (Talents isn't in the default radial-menu ring — reached it via the shell's long-press
  customize-ring flow, a pre-existing, unrelated shell mechanic.)
