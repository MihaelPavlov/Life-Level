---
tags: [lifelevel, design]
aliases: [UI Patterns, Cards, Overlays]
---
# UI Patterns

> Reusable interaction and layout patterns that appear across multiple screens.

## Radial FAB menu

Central anchor for secondary navigation. Details: [[Shell and Radial FAB]].

- Tap FAB → ring of 6 items orbits out at 130px radius
- Drag the ring to rotate; release to snap to nearest item
- Long-press FAB → `CustomizeRingSheet` (reorder items)
- Scrim backdrop at 80% opacity dims the rest of the app

## Bottom nav bar

4 tabs, 82px tall. Each tab: emoji + label, highlighted blue when active. Content persists between tab switches (IndexedStack).

## Cards

The universal container for home / profile / quest content:
- Surface color: `AppColors.surface` (or `surfaceElevated` for raised)
- 12–16px rounded corners
- 16–20px inner padding
- Optional: gradient header, glow border (e.g., active boss = red glow)

Variant: `HomeCard` adds an optional gradient header strip.

## Progress bars

- Gradient fill (blue-to-purple for XP, red-to-darker-red for boss HP)
- Thin (6–8px) for compact displays
- Thick (16–20px) for hero XP bar

## Progress grids

Used for:
- 7-day streak grid (each day a small square, filled if active)
- 7-day login reward ladder (Day 7 is the climax)
- Quest progress cells

## Stat gems

5 color-coded stat buttons on home screen:
- STR (red), END (blue), AGI (green), FLX (purple), STA (orange)
- Each displays current value + gear bonus chip
- Tap → `StatDetailSheet` with description + boosting activities + perks

## Global overlays

Rendered above any screen by `MainShell`:

| Overlay | Style | Trigger |
|---------|-------|---------|
| `LevelUpOverlay` | Full-screen modal, fade-in | `LevelUpNotifier` event |
| `ItemObtainedOverlay` | Slide-up card, rarity-coloured | `ItemObtainedNotifier` event |
| `InventoryFullOverlay` | Slide-up warning with level hint | `InventoryFullNotifier` event |
| `LoginRewardScreen` | Dialog with claim button | App resume + `loginRewardAvailable` |

## Bottom sheets

Pattern for secondary detail:
- Drag handle at top
- Scrim fade-in
- Can cover ≤ 90% of screen
- Closes on scrim tap or drag-down

Used for: `StatDetailSheet`, `XpHistorySheet`, `NodeDetailSheet`, `CustomizeRingSheet`, `BossNodeSheet`, `ChestNodeSheet`, etc.

## Loading states

- **Shimmer skeletons** for initial loads (quest cards, activity history)
- **Spinner** for top-level auth gate
- **Pull-to-refresh** on home, profile, quests, boss list

## Empty / error states

Each list screen has:
- `XEmpty` widget — friendly illustration + CTA
- `XError` widget — error message + retry button
- `XShimmer` widget — skeleton while loading

## Related
- [[Colors and Typography]]
- [[Shell and Radial FAB]]
- [[Global Event Pattern]]
- [[Screen Inventory]]
