---
tags: [lifelevel, backend]
aliases: [Activity Module, ActivityService]
---
# Activity

> Owns the workout log. Converts raw activity data (duration, distance, calories, HR) into XP + stat gains, then fans out to Streak, Quest, and Map modules.

## Entities

### Activity
```csharp
class Activity {
  Guid Id, CharacterId;
  ActivityType Type;
  int DurationMinutes;
  double DistanceKm;
  int Calories, HeartRateAvg;
  string? ExternalId;          // "provider:nativeId" for dedup (null for manual)
  int XpGained;
  int StrGained, EndGained, AgiGained, FlxGained, StaGained;
  int Steps;
  DateTime LoggedAt;
}
```

## ActivityService

Implements: `IActivityStatsReadPort`, `IActivityLogPort`, `IActivityExternalIdReadPort`.

### LogActivityAsync(userId, LogActivityRequest) → LogActivityResult

1. Compute XP + stats via the formula below.
2. Load gear XP bonus via `IGearBonusReadPort.GetEquippedBonusesAsync`; apply `xp *= (1 + pct/100)`.
3. Insert `Activity` row with computed values.
4. **Award XP** via `ICharacterXpPort.AwardXpAsync` → returns `LeveledUp` + `NewLevel`.
5. **Apply stat gains** via `ICharacterStatPort.ApplyStatGainsAsync`.
6. **Publish `ActivityLoggedEvent`** → consumed by `StreakActivityHandler` and `QuestActivityHandler`.
7. **Add map travel distance** via `IMapDistancePort.AddDistanceAsync`.
8. **Advance quests** via `IQuestProgressPort.UpdateProgressFromActivityAsync` (returns completed quests + all-5-bonus flag).
9. **Read current streak** via `IStreakReadPort.GetCurrentStreakAsync`.
10. Return `LogActivityResult` with everything the mobile UI needs to celebrate.

### LogExternalActivityAsync(...)

Same as LogActivity but for 3rd-party integrations (Strava webhook, Health Connect batch, Garmin). Stores `ExternalId` for dedup.

### Other methods

- `GetHistoryAsync(userId)` — last 20 activities as `ActivityHistoryDto`
- `GetWeeklyStatsAsync(userId)` — `WeeklyActivityStatsDto(Runs, DistanceKm, XpEarned)`
- `FindActivityIdByExternalIdAsync(characterId, externalId)` — dedup lookup

## XP calculation formula

```csharp
double baseXp = durationMinutes * 3.0;
int str = 0, end = 0, agi = 0, flx = 0, sta = 0;

switch (type) {
  case Running:   end = 2; agi = 1; baseXp *= 1.2; baseXp += distance * 10; break;
  case Cycling:   end = 2; agi = 1; baseXp *= 1.1; baseXp += distance * 8;  break;
  case Gym:       str = 3; sta = 1; baseXp *= 1.0; break;
  case Yoga:      flx = 3; sta = 1; baseXp *= 0.8; break;
  case Swimming:  end = 2; sta = 2; baseXp *= 1.2; break;
  case Hiking:    end = 1; sta = 2; agi = 1; baseXp *= 1.0; baseXp += distance * 6; break;
  case Walking:   end = 1; sta = 1;          baseXp *= 0.8; baseXp += distance * 5; break;
  case Climbing:  str = 2; end = 1; agi = 1; baseXp *= 1.3; break;
}

baseXp += calories / 10;                              // calorie bonus
baseXp *= (1.0 + gearXpBonusPct / 100.0);             // gear bonus
int steps = (type in {Run, Cycle, Hike, Walk}) ? (int)(distance * 1250) : 0;
```

## Ports implemented
- `IActivityStatsReadPort` — `GetWeeklyStatsAsync`
- `IActivityLogPort` — `LogExternalActivityAsync` (for Integrations)
- `IActivityExternalIdReadPort` — dedup check

## Ports consumed
- `ICharacterXpPort`, `ICharacterStatPort`, `ICharacterIdReadPort`
- `IEventPublisher`
- `IStreakReadPort`
- `IQuestProgressPort`
- `IMapDistancePort`
- `IGearBonusReadPort`

## Events raised
- `ActivityLoggedEvent(userId, activityId, type, duration, distance, calories)` — drives streak + quest progress

## Endpoints
- `POST /api/activity/log`
- `GET /api/activity/history`

## Files
- `backend/src/modules/LifeLevel.Modules.Activity/`

## Related
- [[Activity System]]
- [[XP and Leveling]]
- [[Quest]]
- [[Streak]]
- [[Map]]
- [[Items]] (gear XP bonus)
- [[Integrations]] (external activity dedup)
