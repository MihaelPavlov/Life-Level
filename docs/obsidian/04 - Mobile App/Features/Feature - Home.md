---
tags: [lifelevel, mobile]
aliases: [Home Feature, Home Screen]
---
# Feature — Home

> The main landing tab. A dashboard of cards: character header, XP progress, streak grid, daily quests summary, last activity, stat gems, boss progress.

## Files

```
lib/features/home/
├── home_screen.dart
├── home_cards.dart        ← card-level widgets
├── home_widgets.dart      ← atomic widgets + local palette
└── providers/
    └── map_journey_provider.dart
```

## HomeScreen

`ConsumerStatefulWidget` that:
1. Fetches `CharacterProfile` via `characterProfileProvider`.
2. Renders a scrolling column of cards (see below).
3. Exposes `HomeScreenState.refresh()` — called when MainShell switches to Home tab.

## Cards (home_cards.dart)

| Widget | Purpose |
|--------|---------|
| `HomeHeader` | Greeting, avatar, username, rank + title badges, notification dot |
| `HomeXpCard` | XP progress bar to next level, total XP |
| `HomeStreakCard` | 7-day streak grid + shield status |
| `HomeQuestsCard` | 5 daily quests with progress + all-5 bonus XP banner |
| `HomeLastActivityCard` | Most recent workout summary |
| `HomeStatsRow` | STR/END/AGI/FLX/STA gems (tappable → [[Feature - Profile|StatDetailSheet]]) |
| `HomeBossCard` | Active boss HP bar + player damage dealt |
| `HomeMapProgressSection` | Current destination node, distance remaining, XP earned this week |

## Atomic widgets (home_widgets.dart)

- `HomeBadge` — small rounded chip
- `HomeCard` — surface container with optional glow
- `HomeSectionTitle` — section header
- `HomeProgressBar` — gradient progress bar
- `HomeStreakDay` — single day cell in 7-day grid
- `HomeQuestItem` — quest row inside quests card
- `HomeGainChip` — "+3 STR" style chip
- `HomeStatGem` — colour-coded stat gem button
- `HomePulsingLvBadge` — animated pulsing level badge on avatar

Also: `homeFmt()` number formatter + local palette constants.

## MapJourneyProvider

```dart
final mapJourneyProvider = FutureProvider<MapFullData>(
  (ref) => MapService().getFullMap()
);
```

Powers `HomeMapProgressSection` — shows where the user is on the map and how much distance to the next node.

## Related
- [[Character System]]
- [[Feature - Character]]
- [[Feature - Map]]
- [[Feature - Boss]]
- [[State Management]]
