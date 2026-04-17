---
tags: [lifelevel, mobile]
aliases: [Profile Feature, Profile Screen, Profile Tabs]
---
# Feature — Profile

> Tabbed screen covering Overview, Equipment, Inventory, Achievements, and (for admins) Admin. The settings sheet with Integrations + Logout lives here too.

## Files

```
lib/features/profile/
├── profile_screen.dart
├── profile_overview_tab.dart
├── profile_stat_metadata.dart
├── profile_widgets.dart
├── stat_detail_sheet.dart
├── xp_history_sheet.dart
└── tabs/
    ├── profile_overview_tab.dart
    ├── equipment_tab.dart
    ├── inventory_tab.dart
    ├── achievements_tab.dart
    └── admin_tab.dart
```

## ProfileScreen

Owns 4 + 1 tabs:
- Overview
- Equipment
- Inventory
- Achievements
- Admin (only if `ApiClient.isAdmin()` returns true — decoded from JWT role claim)

Also a **settings sheet** with:
- Integrations → `IntegrationsScreen`
- Logout → clears token, pops to LoginScreen

## Overview tab

- `ProfileXpSection` — XP bar, tappable to open [[Feature - Character|XpHistorySheet]]
- `ProfileStatsSection` — 5 stat cards (STR/END/AGI/FLX/STA), each with:
  - Current value
  - Gear bonus chip if equipped (e.g. "+5")
  - +Point button if `availableStatPoints > 0`
  - Tap → `StatDetailSheet`
- `ProfileActivitySummary` — horizontal scroll of weekly mini-cards (runs, distance, streak, XP earned)

## Equipment tab

Paperdoll view. 5 slots (Head, Chest, Hands, Feet, Accessory):
- Each slot shows equipped item icon or empty placeholder
- Tap → select from inventory
- Aggregated gear bonuses shown at the bottom

## Inventory tab

Grid of unequipped items:
- Sort by rarity / type
- 70% full yellow banner; 100% red banner
- Tap → item detail sheet with stats + equip/discard actions

## Achievements tab

List of all achievements from `achievementsProvider`:
- Tier color-coded ribbon
- Unlocked: full colour + "+XP" badge
- In-progress: progress bar with current/target
- Locked: dim + unlock condition

## Admin tab (admin-only)

- Debug utilities: teleport, add distance, adjust level, reset progress, set XP
- Link to web admin panel (`ApiClient.adminPanelUrl`)
- Link to web map editor (`ApiClient.adminMapUrl`)

## profile_stat_metadata.dart

```dart
class StatMeta {
  String key, label, emoji;
  Color color;
  String description;
  List<String> boostingActivities;
  List<String> perks;
}

const kStrMeta = StatMeta(...);
const kEndMeta = StatMeta(...);
const kAgiMeta = StatMeta(...);
const kFlxMeta = StatMeta(...);
const kStaMeta = StatMeta(...);

List<StatData> buildProfileStats(CharacterProfile profile);
Color profileRankColor(String rank);
```

## Sheets

- `StatDetailSheet` — stat description + boosting activities + perks + spend-point button
- `XpHistorySheet` — last 50 XP gain entries with timestamp + source

## Widgets (profile_widgets.dart)

- `ProfileRankBadge`
- `ProfileMiniCard` — emoji + label + value + sub
- `ProfilePlaceholderTab` — coming-soon stub
- `ProfileSheetSection` — bulleted section for bottom sheets

## Related
- [[Character System]]
- [[Feature - Character]]
- [[Feature - Items]]
- [[Feature - Achievements]]
- [[Feature - Integrations]]
