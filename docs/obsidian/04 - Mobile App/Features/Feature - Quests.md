---
tags: [lifelevel, mobile]
aliases: [Quests Feature, Daily Quests, Weekly Quests]
---
# Feature — Quests

> Three tabs (Daily / Weekly / Special) showing quest cards with progress bars and XP rewards. The "all 5 dailies done → +300 XP" banner lives here.

## Files

```
lib/features/quests/
├── screens/
│   ├── quests_screen.dart
│   └── tabs/
│       ├── daily_quests_tab.dart
│       ├── weekly_quests_tab.dart
│       └── special_quests_tab.dart
├── models/
│   └── quest_models.dart
├── services/
│   └── quest_service.dart
├── providers/
│   └── quest_provider.dart
└── widgets/
    ├── quest_card.dart
    ├── daily_bonus_card.dart
    ├── quest_empty.dart
    ├── quest_error.dart
    └── quest_shimmer.dart
```

## quest_models.dart

```dart
enum QuestType { daily, weekly, special }

class QuestCategory {
  static const duration = 'duration';
  static const calories = 'calories';
  static const distance = 'distance';
  static const workouts = 'workouts';
  static const streak = 'streak';
  static const login = 'login';
}

class UserQuestProgress {
  String id, questId, title, description, category;
  int target, current, rewardXp, ordinal;
  bool isCompleted;
  DateTime? completedAt;
  String? completionDate;
  List<int> daysOfWeek;   // for weekly tracking
}
```

## Tabs

- **Daily** — `dailyQuestsProvider` (`AsyncNotifierProvider`); shows 5 cards + daily bonus card when all complete
- **Weekly** — `weeklyQuestsProvider`; shows 3 cards
- **Special** — `specialQuestsProvider` (`FutureProvider.autoDispose`); limited-time / event quests

## QuestService

```dart
Future<List<UserQuestProgress>> getDailyQuests();
Future<List<UserQuestProgress>> getWeeklyQuests();
Future<List<UserQuestProgress>> getSpecialQuests();
```

## QuestCard widget

- Progress bar (`current / target`)
- Category icon (⏱️ duration, 🔥 calories, 📍 distance, 🏋️ workouts)
- XP reward badge
- Completion checkmark

## DailyBonusCard widget

"Complete all 5 daily quests for +300 XP" banner — shown at top of daily tab when not yet claimed.

## Related
- [[Quest System]]
- [[Quest]] (backend)
- [[Activity System]] (logging advances quests)
- [[State Management]]
