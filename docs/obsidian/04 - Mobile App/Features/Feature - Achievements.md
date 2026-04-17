---
tags: [lifelevel, mobile]
aliases: [Achievements Feature]
---
# Feature — Achievements

> Achievement list rendered inside the Profile → Achievements tab. Each achievement shows progress + tier + XP reward.

## Files

```
lib/features/achievements/
├── models/
│   └── achievement_models.dart
├── services/
│   └── achievements_service.dart
└── providers/
    └── achievements_provider.dart
```

## achievement_models.dart

```dart
class AchievementDto {
  String id, title, description, icon, category, tier;
  Color tierColor;      // Common gray, Uncommon green, Rare blue, Epic purple, Legendary gold
  int xpReward;
  double targetValue, currentValue;
  String targetUnit;     // 'km' | 'minutes' | 'workouts' | 'bosses' | 'days'
  bool isUnlocked;
  DateTime? unlockedAt;

  double get progressPercent => (currentValue / targetValue).clamp(0, 1);
  bool get isInProgress => !isUnlocked && currentValue > 0;
}

class CheckUnlocksResult {
  List<String> newlyUnlockedIds;
}
```

## AchievementsService

```dart
Future<List<AchievementDto>> getAllAchievements();   // GET /api/achievements
Future<CheckUnlocksResult> checkUnlocks();           // POST /api/achievements/check-unlocks
```

## achievementsProvider

```dart
final achievementsProvider = FutureProvider<List<AchievementDto>>(
  (ref) => AchievementsService().getAllAchievements()
);
```

## UI (in Profile → Achievements tab)

Three visual states per achievement:
- **Unlocked** — full colour, tier ribbon, XP reward badge, unlock date
- **In-progress** — tier color outline, progress bar, "X / Y target"
- **Locked** — dim, unlock condition text

Category filter chips at top (Exploration, Combat, Social, Fitness, Gameplay).

## Related
- [[Achievements and Titles]]
- [[Achievements]] (backend)
- [[Feature - Profile]]
