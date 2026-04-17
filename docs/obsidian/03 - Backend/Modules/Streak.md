---
tags: [lifelevel, backend]
aliases: [Streak Module, StreakService]
---
# Streak

> Tracks consecutive activity days per user. Awards shields to protect against missed days. Breaks streaks at midnight for inactive users.

## Entity

```csharp
class Streak {
  Guid Id, UserId;
  int Current, Longest;
  DateTime? LastActivityDate;
  int ShieldsAvailable, ShieldsUsed;
  bool ShieldUsedToday;        // reset at midnight UTC
  int TotalDaysActive;         // lifetime; drives shield awards
}
```

## StreakService

Implements: `IStreakReadPort`, `IStreakShieldPort`, `IStreakDailyReset`.

### RecordActivityDayAsync(userId, activityUtcDate)

The single entry point for streak updates. Called after every activity log.

```csharp
var streak = await GetOrCreateAsync(userId);
var last = streak.LastActivityDate?.Date;
var today = activityUtcDate.Date;

if (last == today) return Unchanged;            // same-day no-op
if (last == today.AddDays(-1)) {                // yesterday
    streak.Current++;
}
else if (last == today.AddDays(-2)
         && streak.ShieldsAvailable > 0
         && !streak.ShieldUsedToday) {          // 2-day gap w/ shield
    streak.ShieldsAvailable--;
    streak.ShieldsUsed++;
    streak.ShieldUsedToday = true;
    streak.Current++;
}
else {                                           // broken
    var prev = streak.Current;
    streak.Current = 1;
    await _events.PublishAsync(new StreakBrokenEvent(userId, prev));
}

streak.Longest = Math.Max(streak.Longest, streak.Current);
streak.TotalDaysActive++;
streak.LastActivityDate = today;

if (streak.TotalDaysActive % 7 == 0) streak.ShieldsAvailable++;
```

### UseShieldAsync(userId)

Manual shield consumption (endpoint `POST /api/streak/use-shield`). Only works if `ShieldsAvailable > 0` and `!ShieldUsedToday`. Doesn't change streak number — just "spends" the shield as insurance for later today.

### AddShieldAsync(userId)

`IStreakShieldPort` — grants 1 shield. Called by [[LoginReward]] on Day 3 of the reward cycle.

### GetCurrentStreakAsync(userId)

`IStreakReadPort` — returns `StreakReadDto(Current, Longest, ShieldsAvailable)`.

### CheckAndBreakExpiredStreaksAsync()

`IStreakDailyReset` — midnight job logic:
- Break streaks where gap is 2+ days AND `ShieldsAvailable == 0`.
- Break streaks where gap is 3+ days (regardless of shields).

### ResetShieldUsedTodayFlagsAsync()

Sets `ShieldUsedToday = false` on all Streak rows.

## StreakActivityHandler

`IEventHandler<ActivityLoggedEvent>` — calls `RecordActivityDayAsync` on every activity log.

> [!info] Like Quest, streak is also updated via direct port call from ActivityService (Tier 1). The event handler is redundant but idempotent (same-day no-op rule).

## Ports implemented
- `IStreakReadPort`, `IStreakShieldPort`, `IStreakDailyReset`

## Ports consumed
- `IEventPublisher`

## Events raised
- `StreakBrokenEvent(userId, previousStreak)`

## Endpoints
- `GET /api/streak`
- `POST /api/streak/use-shield`

## Files
- `backend/src/modules/LifeLevel.Modules.Streak/`

## Related
- [[Streak System]]
- [[Activity]]
- [[LoginReward]] (awards shields on Day 3)
- [[DailyResetJob]]
