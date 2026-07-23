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
  Guid? WorldZoneId;            // world-zone boss bridge
  Guid? TrailEncounterTemplateId; // trail blocker bridge
  bool SuppressExpiry;          // true for permanent world-zone bosses
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

### Trail blocker bridge

Blocker-type trail encounters are authored as `TrailEncounterTemplate` rows in [[WorldZone]], but the fight is handled here as a normal Boss.

Flow:

1. `WorldZoneService.AddDistanceAsync` detects a blocker on the current `WorldZoneEdge`.
2. `WorldBossBridgeService` / `BossSpawnAdapter` creates or finds the linked Boss row.
3. The Boss row stores `TrailEncounterTemplateId`.
4. Mobile opens `BossScreen` / `BossBattleView` for that boss.
5. Logged workouts deal boss damage through the normal boss damage pipeline.
6. When defeated, `BossService` calls `IWorldBlockerCompletionPort.ClearBlockerAsync`.
7. [[WorldZone]] clears the blocker and applies pending kilometers.

Important behavior:

- Trail blocker bosses can be fought from the blocker page even though they are not regular local-map boss nodes.
- Blocker HP and retreat timer are surfaced back into the world map encounter DTO.
- Defeated trail blockers are hidden from region detail and ignored by future movement.
- Story and merchant trail encounters are not owned by this module; their active state lives in `UserWorldProgress.ActiveTrailEncounterId`. See [[Map Encounter Updates]].

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
- `IWorldBlockerCompletionPort` (clear defeated trail blockers in [[WorldZone]])
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
- [[Map Encounter Updates]]
- [[WorldZone]]
- [[Map]]
- [[Adventure.Dungeons]]
- [[Items]] (chest drops)
