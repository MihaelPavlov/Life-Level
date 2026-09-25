# Plan - Reward and Progress Animations

Picked from the motion catalog artifact (claude.ai/artifact/2PVMiA8FhdPUTRasFJRDSS). Each moment animates only when a value actually changes on screen, and every one respects `AppMotion.allowsDecorativeMotion` (reduced/off → values just update).

## Shared toolkit — `lib/core/motion/`
- `reward_fx.dart` — overlay effects in global coordinates: fly widgets along an arc, burst, ring, floating text, light beam. Each effect is its own self-removing `OverlayEntry`.
- `motion_widgets.dart` — `FlapText` (split-flap characters), `FlipSwap` (calendar flip on key change), `SlotNumber` (number slides up), `DrawnCheck` (check mark draws itself), `TypewriterText`.

## Moments
| # | Moment | Where | Animation |
|---|---|---|---|
| 1 | Coins | `core/widgets/currency_chip.dart` | Split-flap digits + delta pill |
| 2 | Boss HP | `boss/screens/boss_battle_screen.dart` | Slash, shake, CRIT number, ember burn bar |
| 3 | Quest progress | `rewards/rewards_screen.dart` `_TaskRow` | Fill with leading edge, then check draw |
| 4 | Stat spend | `profile/profile_overview_tab.dart` `ProfileStatCard` | Gauge tick on bar, number slides up, +1 rune |
| 5 | XP | `ProfileXpSection` | Liquid fill, slosh + LEVEL UP on level-up |
| 6 | Streak | `streak/widgets/streak_detail_sheet.dart` | Flame ignite, day count flip, milestone ring |
| 7 | Season track | `season/season_track_screen.dart`, `season_tier_row.dart` | Tier reached pop, claim rays + reward fly-up |
| 8 | Claim all | `rewards/rewards_screen.dart` | Rewards spiral into the points badge + summary pill |
| 9 | Shop | `shop/shop_screen.dart` `_Offer` | SOLD stamp, tile dims, price → Owned |
| 10 | Achievements | `profile/tabs/achievements_tab.dart` | Emboss + tier rays, typed "Completed!" |
| 11 | Title | `titles/widgets/titles_profile_header.dart` (Titles & Ranks) | Nameplate swap (letters drop in) |
| 12 | Journey | `map/widgets/zone_trail.dart` walker | Walker hops along the trail, fill follows |
| 13 | Region chest | `map/screens/region_chests_screen.dart` | Reward tile lids pop + light beam |
| 14 | Zone unlock | `map/widgets/zone_trail.dart` | Fog clears, sparks along the path |
| 15 | Guild raid | `guild/screens/guild_raid_view.dart` Contributions | Bar race + row reorder |

Gear page stat row already uses the Odometer Roll (`gear/widgets/gear_stats_row.dart`).

## Rules
- Diff old vs new in `didUpdateWidget`; never animate on first build.
- Reduced motion: skip decorative effects, keep the value change.
- No layout shift: floating pieces use `Stack(clipBehavior: Clip.none)` or the overlay.

## Status (2026-09-25)
All 15 implemented; `flutter analyze` clean for touched files.

Notes:
- The orange pill on the Profile header is the character **class**, not the title — the title swap lives on the Titles & Ranks header.
- Region chest claims have no backend yet: the lid pop plays when a region's chest is ready, then the existing "not live yet" toast shows. Wire it to the claim call when the endpoint exists.
- Achievements emboss plays for ids returned by `checkUnlocks()` when the tab opens.
- Value widgets ignore changes in the first 1.5 s after mounting so initial data loading doesn't animate.

## Follow-ups (2026-09-25)
- Rewards points track: ready milestones use reward gold + "gift shake + shine" loop (1.6 s); tapping a ready node only claims (no info popup, no InkWell highlight).
- Rewards tasks: "the bar is the button" — a finished task's bar becomes a striped TAP TO CLAIM bar and the whole row claims; the separate CLAIM button is gone.
- Talents Card Draw: "Spotlight" spin (grid dims, spotlight drifts a random 12–16 tile path, settles and lifts the result) + unfold reveal with a rarity bloom (0.8 s).
- Rewards task claim: "chest burst" popup (`rewards/widgets/task_reward_popup.dart`) using `assets/icons/reward_chest_burst.png`; rewards fly into the points badge on close.
- Home NEXT UP card (unlocked only): breathe + light sweep + walking footsteps in the distance pill.
- Region map "Travel here" with banked km: "trail walk" — `ZoneTrail.travel` (`TrailTravel`) walks the hero along the BFS route from the old zone to the new position, banked km counting down on the walker tag; arrival burst + XP, or "x km to go".
