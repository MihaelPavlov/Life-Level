---
tags: [lifelevel, backend]
aliases: [WorldZone Module, World, Overworld]
---
# WorldZone

> The overworld layer — a graph of named regions connected by directed zone edges. Users move between zones by spending real-world distance; each zone contains a [[Map]] of encounter nodes.

## Entities

### World
```csharp
class World {
  Guid Id;
  string Name;
  bool IsActive;
  DateTime CreatedAt;
}
```
Single active world in practice.

### WorldZone
```csharp
class WorldZone {
  Guid Id;
  string Name, Description, Icon, Region;
  int Tier;
  double PositionX, PositionY;
  int LevelRequirement;
  int TotalXp;                  // awarded on first discovery
  double TotalDistanceKm;       // aggregate distance inside zone's map
  bool IsCrossroads;            // instant pass-through (no travel time)
  bool IsStartZone;
  bool IsHidden;
  Guid WorldId;
  ICollection<WorldZoneEdge> EdgesFrom, EdgesTo;
  ICollection<UserZoneUnlock> UnlockedByUsers;
}
```

### WorldZoneEdge
```csharp
class WorldZoneEdge {
  Guid Id, FromZoneId, ToZoneId;
  double DistanceKm;
  bool IsBidirectional;
}
```

### UserWorldProgress
```csharp
class UserWorldProgress {
  Guid Id, UserId, WorldId;
  Guid? CurrentZoneId, CurrentEdgeId;
  double DistanceTraveledOnEdge;
  Guid? DestinationZoneId;
  DateTime UpdatedAt;
  ICollection<UserZoneUnlock> UnlockedZones;
}
```

### UserZoneUnlock
```csharp
class UserZoneUnlock {
  Guid Id, UserId, WorldZoneId, UserWorldProgressId;
  DateTime UnlockedAt;
}
```

## WorldZoneService

### GetFullWorldAsync(userId) → WorldFullResponse
- Character level (for gating UI)
- All zones with node counts (via `IMapNodeCountPort` + `IMapNodeCompletedCountPort`)
- All edges
- User's current position / destination

### SetDestinationAsync(userId, destinationZoneId)
- Validates adjacency (edge must exist in one direction).
- Instant pass-through for `IsCrossroads` zones (no edge needed, teleports).
- Otherwise sets `DestinationZoneId + CurrentEdgeId`.

### AddDistanceAsync(userId, km)
- Adds to `DistanceTraveledOnEdge`.
- On edge completion (`DistanceTraveled >= edge.DistanceKm`):
  - Set `CurrentZoneId = DestinationZoneId`, clear edge, `UserZoneUnlock` row if first arrival.
  - **First-time arrival**: award `zone.TotalXp` via `ICharacterXpPort`.

### CompleteZoneAsync(userId, zoneId)
Force-complete a zone (used by admin / manual completion). Awards TotalXp (if not previously awarded).

## Default regions (from CLAUDE.md)

- Forest of Endurance
- Mountains of Strength
- Ocean of Balance

Seeded by [[Seeders|WorldSeeder]].

## Ports consumed
- `ICharacterXpPort` (zone-discovery XP)
- `ICharacterLevelReadPort` (level gating)
- `IMapNodeCountPort`, `IMapNodeCompletedCountPort`

## Endpoints
- `GET /api/world/full`
- `PUT /api/world/destination`
- `POST /api/world/debug/add-distance`
- `POST /api/world/zone/{zoneId}/complete`

## Files
- `backend/src/modules/LifeLevel.Modules.WorldZone/`

## Related
- [[Adventure Map and World]]
- [[Map]]
- [[Activity]]
- [[Seeders]]
