---
tags: [lifelevel, game-design]
aliases: [Daily Login, Login Cycle]
---
# Login Rewards

> A 7-day repeating reward cycle that incentivises daily engagement. Climaxes on Day 7 with an XP Storm flag.

## State per user

```csharp
class LoginReward {
  int DayInCycle;           // 0..6, rolls over
  DateTime? LastClaimedAt;
  bool ClaimedToday;
  int TotalLoginDays;       // lifetime
}
```

## The 7-day reward table

```csharp
(int Xp, bool IncludesShield, bool IsXpStorm) RewardTable = [
  (50,  false, false),  // Day 1
  (75,  false, false),  // Day 2
  (100, true,  false),  // Day 3 — +1 streak shield
  (125, false, false),  // Day 4
  (150, false, false),  // Day 5
  (200, false, false),  // Day 6
  (300, false, true),   // Day 7 — XP Storm climax
];
```

**Day 3 → +1 Streak Shield** (via `IStreakShieldPort.AddShieldAsync`).
**Day 7 → XP Storm flag** (doubles XP for the window — exact storm duration is a Phase 7 target).

## Claim flow

`POST /api/login-reward/claim` → `LoginRewardService.ClaimDailyRewardAsync`:

1. Throws if `ClaimedToday == true`.
2. `DayInCycle = (DayInCycle + 1) % 7`.
3. Reads `RewardTable[DayInCycle]`.
4. Awards XP via `ICharacterXpPort.AwardXpAsync`.
5. If shield: `IStreakShieldPort.AddShieldAsync`.
6. Sets `ClaimedToday = true`, `LastClaimedAt = now`, `TotalLoginDays++`.

Returns `LoginRewardClaimResult(DayInCycle, XpAwarded, IncludesShield, IsXpStorm, LeveledUp, NewLevel?)`.

## Status endpoint

`GET /api/login-reward/status` → `LoginRewardStatusDto`:

- `DayInCycle` — what day you'll be on **next** claim
- `ClaimedToday` — if already claimed
- `NextRewardXp`, `NextRewardIncludesShield`, `NextRewardIsXpStorm` — preview
- `TotalLoginDays` — lifetime count

## Midnight reset

The [[DailyResetJob]] calls `ResetDailyClaimFlagsAsync` at midnight UTC, setting `ClaimedToday = false` for all users so they can claim again.

## Mobile trigger

`MainShell` shows `LoginRewardScreen` as a dialog on app resume **if `loginRewardAvailable == true`** in the character profile response. Flag `_loginRewardShown` prevents duplicate dialogs within the same session.

## Related
- [[Streak System]] (Day 3 shield grant)
- [[XP and Leveling]] (Day 7 XP storm)
- [[LoginReward]] (backend module)
- [[Feature - Login Reward]] (mobile)
- [[DailyResetJob]]
