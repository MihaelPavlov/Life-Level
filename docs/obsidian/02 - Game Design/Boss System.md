---
tags: [lifelevel, game-design]
aliases: [Bosses, Boss Battles, Guild Raids]
---
# Boss System

> Bosses turn real workouts into direct damage. Defeat a boss before its timer expires and claim the XP reward.

## Three boss types

| Type | Travel required | Timer | Players | Implementation status |
|------|-----------------|-------|---------|------------------------|
| Regular boss | Yes — must be at `boss.NodeId` | 7 days | Single | ✅ Implemented |
| Mini-boss | No — can fight from anywhere | 3 days | Single | ✅ Implemented (`IsMini = true`) |
| Guild raid | Varies | Varies | Shared HP, multi-player, boss regens if members slack | ⏳ Design only — not yet implemented |

## Entities

```csharp
class Boss {
  Guid Id; Guid NodeId;
  string Name, Icon;
  int MaxHp, RewardXp, TimerDays = 7;
  bool IsMini;
}

class UserBossState {
  Guid Id, UserId, BossId, UserMapProgressId;
  int HpDealt;
  bool IsDefeated, IsExpired;
  DateTime StartedAt;
  DateTime? DefeatedAt;
}
```

## Damage formula

From `BossService.CalculateDamageFromActivity`:

```
damage = (durationMinutes * 2 + distanceKm * 10 + calories / 5) * activityMultiplier
```

Activity multiplier is **1.0** for most activities (specific overrides TBD).

## Fight lifecycle

1. **Activate** — `POST /api/boss/{bossId}/activate` creates `UserBossState` with `StartedAt = now`.
   - Regular boss: only allowed if `currentNodeId == boss.NodeId`.
   - Mini-boss: always allowed (`CanFight = true` unconditionally).
2. **Deal damage** — `POST /api/boss/{bossId}/damage` (direct int) or `/damage/activity` (activity-derived).
   - Increments `HpDealt`. Caps at `MaxHp`.
3. **Just defeated** — when `HpDealt >= MaxHp` for the first time:
   - `IsDefeated = true`, `DefeatedAt = now`.
   - Award `boss.RewardXp` via `ICharacterXpPort`.
   - `JustDefeated = true` in the response.
4. **Timer expiry** — if `StartedAt + TimerDays < now` and not defeated, `IsExpired = true` (checked on reads + cleanup).

## Ranks are awarded from bosses

Defeating bosses drives the rank ladder (see [[Character System]]):

- 0 → Novice
- 10 → Warrior
- 25 → Champion
- 50 → Legendary

`TitleService.CheckAndGrantTitlesAsync` is called after each defeat to evaluate thresholds.

## Debug endpoints

- `POST /api/boss/{bossId}/debug/set-hp` — force HP dealt
- `POST /api/boss/{bossId}/debug/force-defeat`
- `POST /api/boss/{bossId}/debug/force-expire`
- `POST /api/boss/{bossId}/debug/reset`

## Guild raids (future)

Per CLAUDE.md:
- Shared HP pool across all guild members
- All members contribute damage
- Boss regenerates HP if members slack
- Top damage dealer gets bonus XP

None of the guild-raid entities exist yet — this is Phase 7/8 work.

## Related
- [[Adventure Map and World]]
- [[Achievements and Titles]]
- [[Activity System]] (drives damage)
- [[Adventure.Encounters]] (backend)
- [[Feature - Boss]] (mobile)
