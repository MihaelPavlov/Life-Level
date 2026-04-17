---
tags: [lifelevel, mobile]
aliases: [Streak Feature, Use Shield]
---
# Feature — Streak

> Streak data provider + "use shield" action. Displayed in multiple places (home, profile) rather than its own dedicated screen.

## Files

```
lib/features/streak/
├── models/
│   └── streak_models.dart
├── services/
│   └── streak_service.dart
└── providers/
    └── streak_provider.dart
```

## streak_models.dart

```dart
class StreakData {
  int current, longest, shieldsAvailable;
  bool shieldUsedToday;
  DateTime? lastActivityDate;
  int totalDaysActive;
}

class UseShieldResult {
  bool success;
  String message;
  int shieldsRemaining;
}
```

## StreakService

```dart
Future<StreakData> getStreak();            // GET /api/streak
Future<UseShieldResult> useShield();       // POST /api/streak/use-shield
```

## StreakNotifier

```dart
final streakProvider = AsyncNotifierProvider<StreakNotifier, StreakData>(...);

class StreakNotifier extends AsyncNotifier<StreakData> {
  Future<UseShieldResult> useShield();  // preserves streak for 1 missed day
  Future<void> refresh();
}
```

## Where displayed

- **Home header** — current streak badge (`HomeHeader`)
- **Home streak card** — 7-day grid + shield icon (`HomeStreakCard`)
- **Profile overview** — current, longest, shields (`ProfileActivitySummary`)

## Related
- [[Streak System]]
- [[Streak]] (backend)
- [[Feature - Home]]
- [[Feature - Profile]]
