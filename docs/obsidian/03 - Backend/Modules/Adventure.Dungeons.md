---
tags: [lifelevel, backend]
aliases: [Adventure Dungeons, Dungeon Module, Crossroads Module]
---
# Adventure.Dungeons

> Owns multi-floor dungeons and branching crossroads. Both are encounter nodes on the [[Map]], rewarded with XP per progression step.

## Entities

### DungeonPortal
```csharp
class DungeonPortal {
  Guid Id, NodeId;
  string Name;
  int TotalFloors;
  ICollection<DungeonFloor> Floors;
  ICollection<UserDungeonState> UserStates;
}
```

### DungeonFloor
```csharp
class DungeonFloor {
  Guid Id, DungeonPortalId;
  int FloorNumber;
  string Name;
  int RewardXp;             // awarded on advance to this floor
}
```

### Crossroads
```csharp
class Crossroads {
  Guid Id, NodeId;
  string Name;
  ICollection<CrossroadsPath> Paths;
}
```

### CrossroadsPath
```csharp
class CrossroadsPath {
  Guid Id, CrossroadsId;
  string PathName;
  Guid? LeadsToNodeId;      // teleport destination
  int RewardXp;
  string Description;
}
```

### User states
```csharp
class UserDungeonState {
  Guid Id, UserId, DungeonPortalId, UserMapProgressId;
  int CurrentFloor;
  bool IsDefeated;
  DateTime? DefeatedAt;
}

class UserCrossroadsState {
  Guid Id, UserId, CrossroadsId, UserMapProgressId;
  Guid? ChosenPathId;
  bool IsCompleted;
  DateTime? CompletedAt;
}
```

## DungeonService

- `GetAllDungeonsForUserAsync(userId)` → List<DungeonListItemDto>
- `EnterDungeonAsync(userId, dungeonId)` — creates state at `CurrentFloor=1`
- `AdvanceFloorAsync(userId, dungeonId)` — increments floor, awards `floor.RewardXp`
- `GetStateAsync(userId, dungeonId)` — current state
- `CompleteDungeonAsync(userId, dungeonId)` — marks defeated, awards final XP

## CrossroadsService

- `GetAllCrossroadsForUserAsync(userId)` → List<CrossroadsListItemDto>
- `ChoosePathAsync(userId, crossroadsId, pathId)`:
  - Creates `UserCrossroadsState` with `ChosenPathId`
  - Awards `path.RewardXp` via `ICharacterXpPort`
  - Teleports user's `UserMapProgress.CurrentNodeId` to `path.LeadsToNodeId`
- `GetStateAsync(userId, crossroadsId)`

## Ports consumed
- `ICharacterXpPort`

## Endpoints

**Dungeons:**
- `GET /api/dungeon`
- `POST /api/dungeon/{dungeonId}/enter`
- `POST /api/dungeon/{dungeonId}/advance-floor`
- `GET /api/dungeon/{dungeonId}/state`
- `POST /api/dungeon/{dungeonId}/complete`

**Crossroads:**
- `GET /api/crossroads`
- `POST /api/crossroads/{crossroadsId}/choose-path/{pathId}`

## Files
- `backend/src/modules/LifeLevel.Modules.Adventure.Dungeons/`

## Related
- [[Adventure Map and World]]
- [[Map]]
- [[Adventure.Encounters]]
