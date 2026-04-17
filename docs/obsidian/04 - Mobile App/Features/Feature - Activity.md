---
tags: [lifelevel, mobile]
aliases: [Activity Feature, Log Activity]
---
# Feature — Activity

> Manual activity logging form + history screen. The logging flow is where XP celebrations, level-up overlays, and item-obtained popups originate.

## Files

```
lib/features/activity/
├── screens/
│   ├── log_activity_screen.dart
│   └── recent_activities_screen.dart
├── models/
│   └── activity_models.dart
├── services/
│   └── activity_service.dart
└── providers/
    └── activity_provider.dart
```

## LogActivityScreen

Form inputs:
- Activity type (8 types, emoji-coded chips)
- Duration (minutes)
- Distance (km, optional)
- Calories (optional)
- Heart rate average (optional)

On submit:
1. `ActivityService().logActivity(LogActivityRequest)` → `LogActivityResult`
2. Result overlay shows: XP gained, stats gained, gear XP-bonus chip, completed quests, streak update, all-5-dailies bonus
3. If `result.leveledUp`: `LevelUpNotifier.instance.notify(result.newLevel!)`
4. For each item in `result.itemsObtained`: `ItemObtainedNotifier.instance.notify(item)`
5. For each blocked item: `InventoryFullNotifier.instance.notify(blocked)`
6. Invalidate: character profile, quests, activity history, streak, map journey

## activity_models.dart

```dart
enum ActivityType { running, cycling, gym, yoga, swimming, hiking, climbing, walking }

class LogActivityRequest {
  ActivityType type;
  int durationMinutes;
  double? distanceKm;
  int? calories;
  int? heartRateAvg;
}

class LogActivityResult {
  String activityId;
  int xpGained, strGained, endGained, agiGained, flxGained, staGained;
  bool leveledUp; int? newLevel;
  List<CompletedQuestSummary> completedQuests;
  bool streakUpdated; int currentStreak;
  bool allDailyQuestsCompleted; int bonusXpAwarded;
  int xpBonusApplied;           // from equipped gear
  List<BlockedItemInfo> blockedItems;
}
```

## RecentActivitiesScreen

Lists last 20 activities from `GET /api/activity/history`. Rows show type emoji, duration, distance, date.

## ActivityService

```dart
Future<LogActivityResult> logActivity(LogActivityRequest request);  // POST /api/activity/log
Future<List<ActivityHistoryDto>> getHistory();                      // GET /api/activity/history
```

## activityHistoryProvider

```dart
final activityHistoryProvider = FutureProvider<List<ActivityHistoryDto>>(
  (ref) => ActivityService().getHistory()
);
```

## Related
- [[Activity System]]
- [[XP and Leveling]]
- [[Activity]] (backend)
- [[Global Event Pattern]]
- [[Feature - Home]] (displays recent activities card)
- [[Feature - Quests]] (quests advance from activity logs)
