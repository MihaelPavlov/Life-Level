---
tags: [lifelevel, backend]
aliases: [Daily Reset, Midnight Cron]
---
# DailyResetJob

> An `IHostedService` that runs every day at midnight UTC to reset daily state — streak break checks, shield-used-today flags, login-claim flags.

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

### Login reward cleanup ([[LoginReward]] module via `ILoginRewardDailyReset`)

```csharp
await _loginRewardReset.ResetDailyClaimFlagsAsync();
// UPDATE LoginRewards SET ClaimedToday = false;
```

## Why midnight UTC (not local time)

- Consistent across users regardless of timezone.
- Simple to reason about in server code.
- Mobile app doesn't care — just shows claim-available flag from `CharacterProfileResponse`.

Future consideration: user-local midnight (would require storing `TimeZone` per user and scheduling per-timezone).

## Ports consumed

- `IStreakDailyReset` (from [[SharedKernel]])
- `ILoginRewardDailyReset` (from [[SharedKernel]])

## Related
- [[Streak System]]
- [[Login Rewards]]
- [[Architecture Overview]]
