---
tags: [lifelevel, mobile]
aliases: [Character Feature, CharacterProfile]
---
# Feature — Character

> Character profile data source. Provides the `CharacterProfile` stream consumed by Home, Profile, and XP-history sheets.

## Files

```
lib/features/character/
├── models/
│   ├── character_profile.dart
│   ├── character_class.dart
│   └── xp_history_entry.dart
├── services/
│   └── character_service.dart
└── providers/
    └── character_provider.dart
```

## CharacterProfile model

```dart
class CharacterProfile {
  String username, avatarEmoji, className, classEmoji, rank;
  int level, xp, xpForCurrentLevel, xpForNextLevel;
  int strength, endurance, agility, flexibility, stamina;
  int weeklyRuns, weeklyXpEarned;
  double weeklyDistanceKm;
  int currentStreak, availableStatPoints;
  bool loginRewardAvailable;     // triggers LoginRewardScreen dialog on resume
  GearBonusesDto? gearBonuses;   // sum of equipped items
}
```

## CharacterClass model

```dart
class CharacterClass {
  String id, name, emoji, description, tagline;
  double strMultiplier, endMultiplier, agiMultiplier, flxMultiplier, staMultiplier;
}
```

## XpHistoryEntry model

```dart
class XpHistoryEntry {
  String source, emoji, description;
  int xp;
  DateTime earnedAt;
}
```

## CharacterService

```dart
Future<List<CharacterClass>> getClasses();          // GET /api/classes
Future<CharacterSetupResult> setupCharacter(String classId, String avatar);
Future<CharacterProfile> getProfile();              // GET /api/character/me
Future<List<XpHistoryEntry>> getXpHistory();        // GET /api/character/xp-history (last 50)
Future<void> spendStatPoint(String stat);           // POST /api/character/spend-stat
```

## CharacterNotifier

```dart
final characterProfileProvider =
    AsyncNotifierProvider<CharacterNotifier, CharacterProfile>(...);

class CharacterNotifier extends AsyncNotifier<CharacterProfile> {
  Future<void> refresh() async {
    final next = await CharacterService().getProfile();
    // Level-up detection:
    if (state.valueOrNull != null && next.level > state.value!.level) {
      LevelUpNotifier.instance.notify(next.level);
    }
    state = AsyncData(next);
  }

  Future<void> spendStatPoint(String stat) async {
    await CharacterService().spendStatPoint(stat);
    await refresh();
  }
}
```

## xpHistoryProvider

```dart
final xpHistoryProvider = FutureProvider.autoDispose<List<XpHistoryEntry>>(
  (ref) => CharacterService().getXpHistory()
);
```

`autoDispose` = refetches whenever the XP history sheet opens.

## Related
- [[Character System]]
- [[XP and Leveling]]
- [[Character]] (backend)
- [[Feature - Profile]]
- [[Feature - Home]]
- [[Global Event Pattern]] (LevelUpNotifier trigger)
