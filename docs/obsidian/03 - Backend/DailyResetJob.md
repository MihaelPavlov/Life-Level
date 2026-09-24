---
tags: [lifelevel, backend]
aliases: [Daily Reset, Midnight Cron]
---
# DailyResetJob

> An `IHostedService` that runs every day at midnight UTC to reset daily state, including streak break checks and shield-used-today flags.

## Location

`backend/src/LifeLevel.Api/Infrastructure/Jobs/DailyResetJob.cs`

## Schedule

```csharp
var nextMidnight = DateTime.UtcNow.Date.AddDays(1);
var delay = nextMidnight - DateTime.UtcNow;
await Task.Delay(delay, stoppingToken);
// ... do work
// loop to next midnight
```

Registered in `Program.cs` as `AddHostedService<DailyResetJob>()`.

## What it does at midnight UTC

### Streak cleanup ([[Streak]] module via `IStreakDailyReset`)

```csharp
await _streakReset.CheckAndBreakExpiredStreaksAsync();
// For each Streak row:
//   - if LastActivityDate is 2+ days ago AND ShieldsAvailable == 0 → break (Current = 0)
//   - if LastActivityDate is 3+ days ago (regardless of shields) → break
```

```csharp
await _streakReset.ResetShieldUsedTodayFlagsAsync();
// UPDATE Streaks SET ShieldUsedToday = false;
```

## Why midnight UTC (not local time)

- Consistent across users regardless of timezone.
- Simple to reason about in server code.
- Daily and Weekly reward tracks expose their own UTC reset timestamps.

Future consideration: user-local midnight (would require storing `TimeZone` per user and scheduling per-timezone).

## Ports consumed

- `IStreakDailyReset` (from [[SharedKernel]])

## Related
- [[Streak System]]
- [[Architecture Overview]]
