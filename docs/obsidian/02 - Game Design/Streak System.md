---
tags: [lifelevel, game-design]
aliases: [Streak, Streak Shield]
---
# Streak System

> The streak rewards daily discipline and punishes gaps. A shield mechanism lets users miss one day per 7 without losing their streak.

## Streak state per user

```csharp
class Streak {
  int Current;               // current consecutive-day count
  int Longest;               // personal best
  DateTime? LastActivityDate;
  int ShieldsAvailable;      // unused shields
  int ShieldsUsed;           // lifetime used
  bool ShieldUsedToday;      // prevents stacking in one day
  int TotalDaysActive;       // lifetime; drives shield awarding
}
```

## Streak update rules (RecordActivityDayAsync)

When an activity is logged, `StreakService.RecordActivityDayAsync(userId, utcDate)`:

| Case | Condition | Effect |
|------|-----------|--------|
| Same day | `utcDate == LastActivityDate` | No-op (idempotent) |
| Yesterday | `utcDate == LastActivityDate + 1` | `Current++` |
| 2 days ago + shield | `gap == 2` && `ShieldsAvailable > 0` && `!ShieldUsedToday` | Consume shield, `Current++`, `ShieldUsedToday = true` |
| Otherwise | gap ≥ 3, or gap 2 without shield | **Broken** → `Current = 1`, publish `StreakBrokenEvent` |

Every successful increment: `Longest = max(Longest, Current)`, `TotalDaysActive++`.

## Shield cadence

Every **7 `TotalDaysActive`**, `ShieldsAvailable++` (awarded automatically inside `RecordActivityDayAsync`).

Shields can be used implicitly (via the 2-day gap rule) or explicitly via `POST /api/streak/use-shield`.

## Daily midnight reset

The [[DailyResetJob]] runs at midnight UTC and:

1. Calls `CheckAndBreakExpiredStreaksAsync`:
   - Breaks streaks where gap is 2+ days **and** no shield available.
   - Breaks streaks where gap is 3+ days regardless of shields.
2. Calls `ResetShieldUsedTodayFlagsAsync`: sets `ShieldUsedToday = false` for all users.

## Streak and XP

The CLAUDE.md spec says active streaks grant a **×1.5 XP multiplier** (stackable with XP Storm for ×3). The current backend XP formula does not yet apply this — it's a Phase 7 target.

## Endpoints

- `GET /api/streak` — `StreakDto`
- `POST /api/streak/use-shield` — consume shield manually; returns `{ success, message, shieldsRemaining }`

## Design intent (from CLAUDE.md)

- Daily login required to maintain streak — but in current implementation the streak updates from activities, not logins.
- 7-day reward cycle (Day 7 = ×1.5 XP bonus).
- 30-day milestone unlocks legendary cosmetic.
- Broken-streak recovery screen with motivational messaging.

## Related
- [[Activity System]]
- [[Login Rewards]]
- [[Streak]] (backend module)
- [[Feature - Streak]] (mobile)
- [[DailyResetJob]]
