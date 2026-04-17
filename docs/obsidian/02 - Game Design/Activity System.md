---
tags: [lifelevel, game-design]
aliases: [Activity Types, Workout Types]
---
# Activity System

> Activities are the engine of the game: every logged or imported workout converts into XP, stat gains, and map movement.

## Supported activity types

The `ActivityType` enum (backend + mobile) has 8 values:

| Type | Emoji | Primary stats | XP multiplier | Distance bonus |
|------|-------|---------------|---------------|----------------|
| Running | 🏃 | +2 END, +1 AGI | ×1.2 | +10 XP / km |
| Cycling | 🚴 | +2 END, +1 AGI | ×1.1 | +8 XP / km |
| Gym | 💪 | +3 STR, +1 STA | ×1.0 | – |
| Yoga | 🧘 | +3 FLX, +1 STA | ×0.8 | – |
| Swimming | 🏊 | +2 END, +2 STA | ×1.2 | – |
| Hiking | 🥾 | +1 END, +2 STA, +1 AGI | ×1.0 | +6 XP / km |
| Walking | 🚶 | +1 END, +1 STA | ×0.8 | +5 XP / km |
| Climbing | 🧗 | +2 STR, +1 END, +1 AGI | ×1.3 | – |

## What a logged activity contains

```csharp
LogActivityRequest {
  ActivityType type;
  int DurationMinutes;     // required
  double? DistanceKm;      // optional (cardio activities)
  int? Calories;           // optional
  int? HeartRateAvg;       // optional
}
```

## Logging channels

1. **Manual** — `LogActivityScreen` in the mobile app.
2. **Health Connect** — Android foreground sync (every > 15 min since last sync, or manual). See [[Health Connect]].
3. **Strava webhook** — real-time push after athlete saves an activity. See [[Strava]].
4. **Garmin OAuth** — scheduled / on-demand pull. See [[Garmin]].

External activities are **deduplicated** by `ExternalId` (format `"provider:nativeId"`) via the `ExternalActivityRecord` table.

## What logging produces

```csharp
LogActivityResult {
  int XpGained;
  int StrGained, EndGained, AgiGained, FlxGained, StaGained;
  int Steps;
  bool LeveledUp; int? NewLevel;
  List<CompletedQuestSummary> CompletedQuests;
  bool StreakUpdated; int CurrentStreak;
  bool AllDailyQuestsCompleted; int BonusXp;     // +300 XP once/day
  int XpBonusApplied;                            // from gear
  List<BlockedItemInfo> BlockedItems;            // inventory full
}
```

## Step calculation

Cardio activities (Running, Cycling, Hiking, Walking): **`distanceKm × 1250`** steps. Others: 0.

## Related
- [[XP and Leveling]]
- [[Character System]]
- [[Activity]] (backend module)
- [[Feature - Activity]] (mobile)
- [[Activity Type Mapping]] (integrations)
- [[Streak System]]
- [[Quest System]]
