# Plan - Game Modes (Burn Chain, Treasure Delve)

Status: **server-authoritative implementation completed 2026-09-30**. Progress, random rolls, entry limits, cooldowns, item grants, Coins, and Talent Crystals are owned by `LifeLevel.Modules.Modes`; Flutter is an API client.

Design sources (artifacts):
- Bottom nav with the Mode tab: https://claude.ai/artifact/C9QgrRH7XGEz8oRsfmYew5
- Treasure Delve flow: https://claude.ai/artifact/7WGZFBEELdGtTcQRivYq3m
- Burn Chain flow + Modes page (banner list): https://claude.ai/artifact/SHYyXwRS4evtsdtNUEiCL8

## Goals
1. The bottom bar is **Home · Gear · [Map] · Mode · Profile**. Mode is a real tab (`_navIds` index 3) that opens the **Modes** page: one painted banner per mode, plus a "coming soon" card.
2. **Burn Chain:** a 24h window where each workout must burn more calories than the last. A beat pays calories × 2.
3. **Treasure Delve:** short 5-chamber runs, entered with runs earned from today's workouts. You choose a path, pass a stat check, then bank or go deeper.

## Burn Chain rules (`burn_chain_rules.dart`)
- Start → 24h window (`kBurnChainWindow`). Only workouts logged inside it and ≥ `kBurnChainMinMinutes` (10) count, taken oldest first.
- The first workout sets the bar and pays `floor(kcal / 5) × 1`.
- A workout that burns **more** than the bar pays `floor(kcal / 5) × 2` and becomes the new bar.
- The first workout that burns the same or less **breaks** the chain. It pays ×1 and nothing after it counts. The chain also ends when the window closes.
- Example: 200 → +40, 320 → +128, 300 → breaks, +60. Total 228.
- The server freezes the chain at break/expiry, grants 1 Talent Crystal for 1–2 beats or 2 for 3+ beats, and prevents another chain until the original 24-hour window ends.

## Treasure Delve rules (`delve_engine.dart`)
- Runs today: each workout of 20+ min earns 1 and 45+ min earns 2, capped at 3 a day. Runs used are counted per day on the device.
- 5 chambers. Each offers **Safe** (guaranteed, coins go straight to *secured*), **Treasure** (stat check, coins go *at risk*, 25% item chance) and **Cursed** (harder check, more coins, 40% item chance). Each path gets a different event, and each event tests one stat (STR/END/AGI/FLX/STA).
- Coins: base 10 / 20 / 35, ×1.5 per chamber deeper, and +20% in rooms testing the **featured stat**, which rotates daily.
- Check: recommended value = the player's average stat × path factor (1.0 / 1.35) × (1 + 0.1 × chamber). Success chance = 0.5 + 1.2 × (stat − rec) / rec, clamped to 10–95%. The screen shows the odds in words.
- After a clear you can **bank** (take secured + at risk) or **continue**. A failed check ends the run and keeps only the secured coins. Leaving mid-run banks.

## Files
- `features/modes/modes_screen.dart`: the Modes tab (banners, wallet chips, ribbon title).
- `features/modes/widgets/mode_banner.dart`, `widgets/mode_ui.dart`: banner, reward tile, CTA buttons, panels.
- `features/modes/services/modes_api_service.dart`: Dio client and server DTO mapping. Obsolete SharedPreferences mode state is deleted after the first successful server read.
- `features/modes/burn_chain/`: `burn_chain_rules.dart` (pure), `burn_chain_provider.dart`, `burn_chain_screen.dart` (intro / live / ended + ×2 sheet).
- `features/modes/treasure_delve/`: `delve_engine.dart` (pure), `delve_provider.dart`, `treasure_delve_screen.dart` (entrance), `delve_run_screen.dart` (choose → check → decide → result).
- Shell: `_navIds` gains `modes`; `ShellTabBar` Mode = index 3; switching to Mode refreshes activity history; `ShellOverlayNotifier.open('burn_chain')` opens the chain.
- Home: *Happening now* shows a live Burn Chain (time left + calories to beat).
- Assets: `assets/Modes/banner_burn_chain.jpg`, `banner_treasure_delve.jpg` (crops of the Emberfall Crater / Abyssal Trench region art).

## Backend implementation
- `LifeLevel.Modules.Modes` persists Burn Chain and Treasure Delve runs and exposes authenticated `/api/modes` endpoints.
- Treasure Delve eligibility and resets use UTC. Base character stats are frozen at start; the server generates options and rolls outcomes.
- Treasure paths can grant unowned Common items (25%); Cursed paths can grant unowned Rare items (40%). Safe paths do not drop items.
- Terminal Delve outcomes settle Coins immediately and grant 1 Talent Crystal at 3–4 clears or 2 at 5 clears. Midnight expiry banks unfinished runs.
- `ModeRewardSettlement` and serializable transactions make terminal payouts retry-safe.
- Remaining presentation-only follow-up: replace the region-art crops with dedicated wide banner art.

## Verification
- `test/features/modes/burn_chain_rules_test.dart`: chain rules, including the 200 / 320 / 300 example.
- `test/features/modes/delve_engine_test.dart`: runs earned, secured vs at risk, fail, bank, clear, odds.
- `test/features/modes/modes_screens_test.dart`: every screen and run phase renders at 390×844 without overflow.
