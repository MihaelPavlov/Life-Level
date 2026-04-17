---
tags: [lifelevel, backend]
aliases: [Achievements Module, AchievementService]
---
# Achievements

> Evaluates 48 tracked achievement conditions (bosses fought, streak days, quests completed, total distance, etc.) and awards XP on first unlock.

## Entities

### Achievement (template)
```csharp
class Achievement {
  Guid Id;
  string Title, Description, Icon;
  AchievementCategory Category;   // Exploration | Combat | Social | Fitness | Gameplay
  AchievementTier Tier;           // Bronze/Silver/Gold/Platinum/Diamond (per seeder)
                                  // OR Common..Legendary (per CLAUDE.md intent)
  int XpReward;
  string ConditionType;           // e.g., "BossesFought", "StreakDaysAtOnce"
  int TargetValue;
  string TargetUnit;              // "bosses", "days", "km", "minutes"
}
```

### UserAchievement
```csharp
class UserAchievement {
  Guid Id, UserId, AchievementId;
  int CurrentValue;
  bool IsUnlocked;
  DateTime? UnlockedAt;
}
```

## AchievementService

### GetAchievementsAsync(userId, category?)

Returns `List<AchievementDto>` with user progress. Sorted by:
1. `IsUnlocked desc` (unlocked first)
2. `UnlockedAt desc` (newest unlocks first)
3. Progress % desc (closer-to-unlock first among locked)
4. Title asc

### CheckUnlocksAsync(userId) → CheckUnlocksResult

For each achievement:
1. Compute current value via `ComputeConditionValueAsync(conditionType, userId)`:
   - `BossesFought` → count `UserBossState.IsDefeated == true`
   - `StreakDaysAtOnce` → `Streak.Longest`
   - `TotalQuestsCompleted` → `UserQuestProgress.IsCompleted == true` count
   - `TotalActivities` → `Activity` count
   - `TotalDistanceKm` → `SUM(Activity.DistanceKm)`
   - ...etc
2. Compare against `TargetValue`.
3. If newly unlocked (was false, now true):
   - `IsUnlocked = true`, `UnlockedAt = now`
   - Award `XpReward` via `ICharacterXpPort`
   - Add to `NewlyUnlockedIds`

## When CheckUnlocksAsync is called

Not yet called automatically (Phase 7 target: fire from event handlers on relevant events). Currently:
- Triggered manually via `POST /api/achievements/check-unlocks`
- Mobile app calls it after boss defeats / activity logs as a safety net

## Ports consumed
- `ICharacterXpPort`, `ICharacterIdReadPort`

## Endpoints
- `GET /api/achievements?category=X`
- `POST /api/achievements/check-unlocks`

## Files
- `backend/src/modules/LifeLevel.Modules.Achievements/`

## Related
- [[Achievements and Titles]]
- [[Character]] (TitleService — parallel system for titles)
- [[Feature - Achievements]] (mobile)
