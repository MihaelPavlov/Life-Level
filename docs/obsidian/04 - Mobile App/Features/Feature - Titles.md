---
tags: [lifelevel, mobile]
aliases: [Titles Feature, Rank Ladder]
---
# Feature — Titles

> Opened from the radial FAB's Titles item. Shows the active title, earned titles grid, locked titles with unlock conditions, and a rank progression ladder.

## Files

```
lib/features/titles/
├── titles_ranks_screen.dart
├── models/
│   └── title_models.dart
├── services/
│   └── titles_service.dart
├── providers/
│   └── titles_provider.dart
└── widgets/
    ├── title_list_item.dart
    ├── rank_ladder_widget.dart
    └── titles_profile_header.dart
```

## title_models.dart

```dart
class TitleDto {
  String id, emoji, name, unlockCondition;
  bool isEarned, isEquipped;
}

class RankProgressionDto {
  String currentRank, nextRank;
  int bossesDefeated, bossesRequiredForNextRank, bossesRemainingForNextRank;
}

class TitlesAndRanksResponse {
  String activeTitleEmoji, activeTitleName;
  List<TitleDto> earnedTitles, lockedTitles;
  RankProgressionDto rankProgression;
}
```

## TitlesRanksScreen

Sections:
1. **TitlesProfileHeader** — large active title emoji + name
2. **Rank ladder widget** — progress to next rank ("Beat 3/15 more bosses")
3. **Earned titles grid** — tap to equip (optimistic update)
4. **Locked titles** — greyed-out with unlock condition text

## TitlesService

```dart
Future<TitlesAndRanksResponse> getTitlesAndRanks();  // GET /api/titles
Future<void> equipTitle(String titleId);             // POST /api/titles/{titleId}/equip
```

## TitlesNotifier

```dart
final titlesProvider = AsyncNotifierProvider<TitlesNotifier, TitlesAndRanksResponse>(...);

class TitlesNotifier extends AsyncNotifier<TitlesAndRanksResponse> {
  Future<void> equipTitle(String titleId) async {
    // Optimistic: update local state first
    final updated = state.value!.copyWith(...);
    state = AsyncData(updated);
    try {
      await TitlesService().equipTitle(titleId);
    } catch (e) {
      // Revert + show error
    }
  }
}
```

## Widgets

- `TitleListItem` — card with emoji + name + rarity/unlock condition
- `RankLadderWidget` — progress bar to next rank with bosses-remaining text
- `TitlesProfileHeader` — large active title display

## Related
- [[Achievements and Titles]]
- [[Character]] (backend — TitleService)
- [[Boss System]] (defeats drive rank)
