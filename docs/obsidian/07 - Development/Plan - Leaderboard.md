# Plan - Leaderboard (with rank-up chest)

Design: Leaderboards & Social canvas, board 1b (https://claude.ai/artifact/5xdxoM6diSYsGTyAY4rTxL).
Status: implemented 2026-09-30 (backend + mobile), not yet committed. The `AddLeaderboardPasses` migration is applied on the next API start (auto-migrate).

## What the player sees
- Adventure Hub tile **Leaderboard** (`ring_leaderboard` icon). It shows the red dot while the rank-up chest holds rewards.
- The screen matches the Region Chests header: back arrow, gem and coin chips, gold "Leaderboard" ribbon, and a period pill ("All-time", "Resets in 3d 4h", or "<guild/region> · …").
- Scopes: **Global** (default) · **Region** · **Guild**. There is no Friends scope until a friends system exists.
- Metrics: **Power** (default, all-time) · **XP**, **Km**, **Boss** damage (weekly, reset Monday 00:00 UTC) · **Streak** (current streak).
- Podium of the top 3 (2nd · 1st · 3rd). Each shows the hero render (`assets/Leaderboard/hero_podium.png`, cropped tight so it centres exactly) standing on a gold, silver or bronze pedestal. Ranks 4–100 follow in a dark list.
- Your row is pinned at the bottom: your rank, your score, and the gap to the next player ("95 power to pass Taro").
- **Rank-up chest:** every player you pass adds a reward to one chest on your row (a ×N badge, which pops in and bobs). One tap plays the existing "You got loot!" chest reveal with the combined coins and gems, and names who you passed.
- A guild board without a guild shows a "Join a guild" card. A region board without a map position shows "No region yet".

## Rules
- Passes are detected on the **global weekly XP** board, whatever board you are looking at. The server stores the up to 10 players just ahead of you (`LeaderboardWatch`). Anyone from that list who is now behind you counts as a pass.
- A pass pays once per player per week, with at most 10 paid passes a week. The reward depends on the rank you climbed to: top 3 = 80 coins + 2 gems, top 10 = 60 coins + 1 gem, otherwise 40 coins.
- Unclaimed passes stay in the chest until it is opened, including across weeks.
- Checks run on `GET /api/leaderboard` and `GET /api/leaderboard/chest`. The chest check also runs whenever Home refreshes progress.
- Not built yet: the "stay ahead for 24h" anti-farming delay, ▲▼ rank moves, and server-first rewards.

## Backend
- Module `LifeLevel.Modules.Leaderboard`:
  - `LeaderboardService`: rank, evaluate passes, open the chest.
  - Entities `LeaderboardPass` (unique per user, passed player and week) and `LeaderboardWatch`.
  - `LeaderboardRules`: week start, pass reward, caps.
- Port `ILeaderboardReadPort` is implemented by `LeaderboardReadAdapter` in the API.
  - It reads XP history, activities, boss combat turns, streaks, guild members and world progress.
  - Power comes from `ICharacterCombatStatsReadPort`, cached for 5 minutes per player. This should move to Redis sorted sets once player counts grow.
- Endpoints: `GET /api/leaderboard?scope=&metric=`, `GET /api/leaderboard/chest`, `POST /api/leaderboard/chest/open`.
- Tests: `LeaderboardServiceTests`, `LeaderboardReadAdapterTests`.

## Mobile
- `features/leaderboard/`: models, service, providers (`leaderboardProvider` family, `leaderboardChestProvider`), `leaderboard_screen.dart`, and `widgets/leaderboard_widgets.dart` (podium, row, chest button, climbed pill).
- Hub tile in `home_adventure_hub.dart`; signal `AdventureHubSignals.leaderboard`.
- Tests: `test/features/leaderboard/leaderboard_screen_test.dart`. The opt-in render is `test/visual/leaderboard_showcase_test.dart`.
