---
tags: [lifelevel, mobile]
aliases: [Radial Menu, Boss FAB, Navigation]
---
# Shell and Radial FAB

> The `MainShell` hosts a bottom tab bar with a centre FAB that expands into a radial menu of 6 items. Items and tabs are customisable.

## Layout constants (`shell_constants.dart`)

```dart
const kNavBarH    = 82.0;                 // bottom nav bar height
const kFabSize    = 62.0;                 // centre FAB diameter
const kRadius     = 130.0;                // radial orbit radius
const kItemSize   = 54.0;                 // individual ring item size
const kFabBottom  = kNavBarH - kFabSize / 2;
const kNavBg      = Color(0xFF111830);
const kCardBg     = Color(0xFF1a2848);
const kRadialScrim = Color(0xCC06080F);   // semi-transparent overlay
```

## Models (`shell_models.dart`)

```dart
class RingItem {
  final String id;           // 'world', 'guild', 'stats', 'battle', 'titles', 'boss', ...
  final String emoji;
  final String label;
  final Color color;
}

class NavTab {
  final String id;           // 'home', 'quests', 'map', 'profile', 'stats', ...
  final String emoji;
  final String label;
}
```

## The catalog

`kAllRingItems` — 10 ring items available: **World, Guild, Stats, Battle, Titles, Boss, Profile, Leaderboard, Map, Quests**.

`kDefaultRingIds` — 6 shown out-of-box: **World, Guild, Stats, Battle, Titles, Boss**.

`kAllNavItems` — 8+ nav tabs available.

`kDefaultNavIds` — 4 shown: **home, quests, map, profile**.

## Opening the ring

Tap the centre FAB (`BossFab` widget) to:
1. Rotate the FAB icon (⚔️ → ✖️)
2. Fade in the scrim backdrop
3. Animate ring items outward from centre to their orbit position
4. Play a subtle spring animation

The ring is draggable — user can rotate the whole ring; it snaps to the nearest item on release (snap animation controller).

## Customisation

Long-press the FAB → `CustomizeRingSheet` bottom sheet:
- Reorder ring items via drag handles
- Save persists to the server via `AuthService.saveRingConfig(List<String> itemIds)`
- The `User.RingItems` collection on the backend stores the selection

## Ring-item → action map

| Item | Action |
|------|--------|
| World | Open [[Feature - Map|WorldMapScreen]] modal |
| Guild | Placeholder (future) |
| Stats | Placeholder |
| Battle | Placeholder |
| Titles | Open [[Feature - Titles|TitlesRanksScreen]] |
| Boss | Open [[Feature - Boss|BossScreen]] |

## Widgets

- `BossFab` — animated centre FAB
- `BottomNavBar` — Material-style tab bar
- `RingItemTile` — single ring tile with emoji + label + colour

## Related
- [[App Architecture]]
- [[Core Infrastructure]]
- [[UI Patterns]]
