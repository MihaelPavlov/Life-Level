---
tags: [lifelevel, backend]
aliases: [LoginReward Module, LoginRewardService]
---
# LoginReward

> Owns the 7-day daily-login reward cycle. Climaxes on Day 7 with a 300-XP payout and an XP Storm flag.

## Entity

```csharp
class LoginReward {
  Guid Id, UserId;
  int DayInCycle;          // 0..6; rolls over
  DateTime? LastClaimedAt;
  bool ClaimedToday;
  int TotalLoginDays;      // lifetime
}
```

## LoginRewardService

Implements: `ILoginRewardReadPort`, `ILoginRewardDailyReset`.

### The reward table

```csharp
private static readonly (int Xp, bool IncludesShield, bool IsXpStorm)[] RewardTable =
[
    (50,  false, false),  // Day 1
    (75,  false, false),  // Day 2
    (100, true,  false),  // Day 3 — +1 streak shield
    (125, false, false),  // Day 4
    (150, false, false),  // Day 5
    (200, false, false),  // Day 6
    (300, false, true),   // Day 7 — XP Storm climax
];
```

### ClaimDailyRewardAsync(userId) → LoginRewardClaimResult

1. Throws if `ClaimedToday == true`.
2. `DayInCycle = (DayInCycle + 1) % 7`.
3. Look up `RewardTable[DayInCycle]`.
4. Award XP via `ICharacterXpPort.AwardXpAsync`.
5. If `IncludesShield`: call `IStreakShieldPort.AddShieldAsync`.
6. Set `ClaimedToday = true`, `LastClaimedAt = now`, `TotalLoginDays++`.

Returns: `{ DayInCycle, XpAwarded, IncludesShield, IsXpStorm, LeveledUp, NewLevel? }`.

### GetStatusAsync(userId) → LoginRewardStatusDto

- `DayInCycle` — day the user will claim **next**
- `ClaimedToday` — whether they already claimed today
- `NextRewardXp`, `NextRewardIncludesShield`, `NextRewardIsXpStorm` — preview
- `TotalLoginDays`

### HasClaimedTodayAsync(userId)

`ILoginRewardReadPort` — used by `CharacterService.GetProfileAsync` to set `loginRewardAvailable` flag on the profile response.

### ResetDailyClaimFlagsAsync()

`ILoginRewardDailyReset` — midnight cron: `UPDATE LoginRewards SET ClaimedToday = false`.

## Ports implemented
- `ILoginRewardReadPort`, `ILoginRewardDailyReset`

## Ports consumed
- `ICharacterXpPort`
- `IStreakShieldPort`

## Endpoints
- `GET /api/login-reward`
- `POST /api/login-reward/claim`

## Files
- `backend/src/modules/LifeLevel.Modules.LoginReward/`

## Related
- [[Login Rewards]]
- [[Streak]] (Day 3 shield grant)
- [[XP and Leveling]] (Day 7 XP Storm)
- [[DailyResetJob]]
