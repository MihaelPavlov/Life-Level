---
tags: [lifelevel, backend]
aliases: [Quest Module, QuestService]
---
# Quest

> Owns daily/weekly/special quest templates and user progress. Activities advance quests; completing all 5 dailies awards a 300-XP bonus.

## Entities

### Quest (template)
```csharp
class Quest {
  Guid Id;
  string Title, Description;
  QuestType Type;             // Daily | Weekly | Special
  string Category;            // duration | calories | distance | workouts | streak | login
  ActivityType? RequiredActivity;
  int TargetValue;
  string TargetUnit;
  int RewardXp;
  int SortOrder;
  bool IsActive;
  ICollection<UserQuestProgress> UserProgress;
}
```

### UserQuestProgress
```csharp
class UserQuestProgress {
  Guid Id, UserId, QuestId;
  int CurrentValue;
  bool IsCompleted;
  DateTime? CompletedAt;
  bool RewardClaimed;
  DateTime AssignedAt, ExpiresAt;
  bool BonusAwarded;          // for the 300-XP all-5-dailies flag
}
```

## QuestService

Implements: `IDailyQuestReadPort`, `IQuestProgressPort`.

### GenerateDailyQuestsAsync(userId)

Assigns **up to 5** active daily quests:

1. Pick 1 from `Duration`.
2. Pick 1 from `Calories` or `Distance`.
3. Pick 3 random from remaining active daily templates.
4. Create `UserQuestProgress` rows with `ExpiresAt = tomorrow midnight UTC`.

### GenerateWeeklyQuestsAsync(userId)

Assigns up to 3 weekly quests with `ExpiresAt = next Sunday midnight UTC`. Also calls `EnsureSpecialQuestsAsync`.

### EnsureSpecialQuestsAsync(userId)

Lazily assigns special quest templates on first request (`ExpiresAt = 2099-12-31 UTC` — effectively never).

### UpdateProgressFromActivityAsync(userId, type, duration, distance, calories)

For each active, non-completed, non-expired `UserQuestProgress`:

1. Match category:
   - `duration` → `+duration`
   - `calories` → `+calories`
   - `distance` → `+distance`
   - `workouts` → `+1`
2. If `CurrentValue >= TargetValue`: mark complete, award `RewardXp` via `ICharacterXpPort`.
3. After all updates: if today's completed-daily count is 5 AND no prior row has `BonusAwarded=true` today → award **+300 XP bonus**, mark the bonus flag.

Returns `QuestProgressUpdateResult(UpdatedQuests[], AllDailyCompleted, BonusXpAwarded)`.

### CountCompletedDailyQuestsAsync(userId)

`IDailyQuestReadPort` — count of `UserQuestProgress` where `Type == Daily`, `IsCompleted == true`, and `CompletedAt` is today UTC.

## QuestActivityHandler

`IEventHandler<ActivityLoggedEvent>` — calls `UpdateProgressFromActivityAsync`.

> [!info] Dual-path update
> Currently `ActivityService.LogActivityAsync` calls `IQuestProgressPort.UpdateProgressFromActivityAsync` **directly** (Tier 1, synchronous) AND `QuestActivityHandler` also fires via the event. Double-update is idempotent because the second pass finds the quest already completed. This will be simplified when the outbox lands.

## Ports implemented
- `IDailyQuestReadPort`
- `IQuestProgressPort`

## Ports consumed
- `ICharacterXpPort`
- `IEventPublisher`

## Events raised
- `QuestCompletedEvent(userId, questId, rewardXp)`
- `AllDailyQuestsCompletedEvent(userId, bonusXp)`

## Endpoints
- `GET /api/quests/daily`
- `GET /api/quests/weekly`
- `GET /api/quests/special`
- `POST /api/quests/generate/daily`
- `POST /api/quests/generate/weekly`

## Files
- `backend/src/modules/LifeLevel.Modules.Quest/`

## Related
- [[Quest System]]
- [[Activity]]
- [[Cross-Module Events]]
