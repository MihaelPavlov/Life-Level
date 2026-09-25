---
type: "query"
date: "2026-09-25T21:56:17.030339+00:00"
question: "Audit the center expandable menu in the bottom navigation and determine what happens if it is removed."
contributor: "graphify"
outcome: "useful"
source_nodes: ["shell/main_shell.dart", "bottom_nav_bar.dart", "MainShell", "Home", "profile"]
---

# Q: Audit the center expandable menu in the bottom navigation and determine what happens if it is removed.

## Answer

Expanded via graph vocab: navigation, menu, tab, shell, bottom, overlay, screen, home, map, quest, profile, shop. Default radial menu contains World, Guild, Stats, Titles, Boss, Season. World duplicates the Map bottom tab. Guild, Titles/Milestones, and Season are accessible through Home Adventure Hub. Stats are shown in Profile Overview, although the radial stats action itself currently resolves to a placeholder/no-op because _screenFor has no stats case. Bosses remain accessible through map and active Home portal flows, but removing the ring removes the persistent generic Boss list shortcut. Long-pressing the center FAB also opens nav/ring customization, so removing it without relocating customization removes that feature. Optional ring entries include Profile, Leaderboard, and Talents; Profile duplicates bottom nav, Talents is in Home Adventure Hub, and Leaderboard appears placeholder/unimplemented in shell routing.

## Outcome

- Signal: useful

## Source Nodes

- shell/main_shell.dart
- bottom_nav_bar.dart
- MainShell
- Home
- profile