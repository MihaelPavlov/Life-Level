---
tags: [lifelevel, backend]
aliases: [Adventure Encounters, Boss Module, Chest Module]
---
# Adventure.Encounters

> Owns Bosses and Chests — the point encounters on the [[Map]]. Also owns per-user state for each encounter (HP dealt, open/closed, timers).

## Entities

### Boss
```csharp
class Boss {
  Guid Id, NodeId;              // 1:1 with MapNode (Boss type)
  string Name, Icon;
  int MaxHp, RewardXp;
  int TimerDays = 7;            // mini bosses typically = 3
  bool IsMini;
}
```

### Chest
```csharp
class Chest {
  Guid Id, NodeId;
  string Name, Icon;
  int RewardXp;
}
```

### UserBossState
```csharp
class UserBossState {
  Guid Id, UserId, BossId, UserMapProgressId;
  int HpDealt;
  bool IsDefeated, IsExpired;
  DateTime StartedAt;
  DateTime? DefeatedAt;
}
```

### UserChestState
```csharp
class UserChestState {
  Guid Id, UserId, ChestId, UserMapProgressId;
  bool IsOpened;
  DateTime? OpenedAt;
}
```

## BossService

### GetAllBossesForUserAsync(userId) → List<BossListItemDto>
- Joins `Boss` + `UserBossState` + `MapNode` info.
- `CanFight = boss.IsMini || currentNodeId == boss.NodeId` (uses `IMapProgressReadPort`).
- Returns activated status, HpDealt, timer expiry, defeat flag.

### ActivateFightAsync(userId, bossId) → UserBossState
- Creates `UserBossState` with `StartedAt = now`.
- Enforces CanFight (throws otherwise).

### DealDamageAsync(userId, bossId, damage) → DealDamageResult
- Increments `HpDealt`, caps at `MaxHp`.
- If crosses MaxHp for first time → `IsDefeated = true`, `DefeatedAt = now`, award `RewardXp` via `ICharacterXpPort`.
- Returns `(HpDealt, MaxHp, IsDefeated, JustDefeated, RewardXpAwarded)`.

### CalculateDamageFromActivity(type, duration, distance, calories) — static helper

```
damage = (durationMinutes * 2 + distanceKm * 10 + calories / 5) * activityMultiplier
```

`activityMultiplier` is 1.0 for most activities.

### Debug methods
- `DebugForceDefeatAsync`, `DebugForceExpireAsync`, `DebugSetHpAsync`, `DebugResetAsync`

## ChestService

### OpenChestAsync(userId, chestId) → OpenChestResult
- Validates `currentNodeId == chest.NodeId`.
- Sets `UserChestState.IsOpened = true`, `OpenedAt = now`.
- Awards `RewardXp` via `ICharacterXpPort`.
- Evaluates `ItemDropRule` entries for this chest via `ItemGrantService` (in [[Items]] module); returns any items granted.

## Ports consumed
- `ICharacterXpPort`
- `IMapProgressReadPort` (for CanFight / chest proximity)
- `IEventPublisher` (for potential future events)

## Endpoints

**Boss:**
- `GET /api/boss`
- `POST /api/boss/{bossId}/activate`
- `POST /api/boss/{bossId}/damage`
- `POST /api/boss/{bossId}/damage/activity`
- `GET /api/boss/{bossId}/state`
- Debug: `set-hp`, `force-defeat`, `force-expire`, `reset`

**Chest:**
- `GET /api/chest`
- `POST /api/chest/{chestId}/open`
- `GET /api/chest/{chestId}/state`

## Files
- `backend/src/modules/LifeLevel.Modules.Adventure.Encounters/`

## Related
- [[Boss System]]
- [[Map]]
- [[Adventure.Dungeons]]
- [[Items]] (chest drops)
