---
tags: [lifelevel, backend]
aliases: [Map Module, MapNode, MapEdge]
---
# Map

> Dungeon-layer graph: nodes are encounters (Boss, Chest, DungeonPortal, Crossroads), edges are distance-costed paths. Users travel the graph by logging real-world activity.

Note: this module owns the **data** (nodes/edges/user progress). The orchestration (`MapService.GetFullMapAsync`, loading Boss/Chest/DungeonPortal/Crossroads by NodeId) lives in [[Architecture Overview|LifeLevel.Api]] to avoid cross-module cycles.

## Entities

### MapNode
```csharp
class MapNode {
  Guid Id;
  string Name, Description, Icon;
  NodeType Type;                 // Boss | Chest | DungeonPortal | Crossroads
  string Region;
  double PositionX, PositionY;   // canvas coords
  int LevelRequirement, RewardXp;
  bool IsStartNode, IsHidden;
  Guid? WorldZoneId;             // FK to WorldZone (cross-module)
  ICollection<MapEdge> EdgesFrom, EdgesTo;
}
```

### MapEdge
```csharp
class MapEdge {
  Guid Id, FromNodeId, ToNodeId;
  double DistanceKm;             // cost to traverse
}
```

Directed edges. If bidirectional, seeded as two rows.

### UserMapProgress
```csharp
class UserMapProgress {
  Guid Id, UserId;
  Guid? CurrentNodeId;
  Guid? CurrentEdgeId;
  double DistanceTraveledOnEdge;
  double PendingDistanceKm;      // unused capacity when arriving mid-edge
  Guid? DestinationNodeId;
  ICollection<UserNodeUnlock> UnlockedNodes;
}
```

### UserNodeUnlock
```csharp
class UserNodeUnlock {
  Guid Id, UserId, MapNodeId;
  DateTime UnlockedAt;
}
```

## Services

**The Map module itself has no service.** It exposes data via ports implemented by repository classes. The orchestration lives in `LifeLevel.Api/Application/Services/MapService.cs`.

## Ports implemented
- `IMapProgressReadPort.GetCurrentNodeIdAsync(userId)` — used by [[Adventure.Encounters]] to gate non-mini boss fights
- `IMapDistancePort.AddDistanceAsync(userId, km)` — called by [[Activity]] on every activity log
- `IMapNodeCountPort.GetNodeCountsByZoneIdsAsync(zoneIds)` — used by [[WorldZone]] to show "3/10 nodes explored"
- `IMapNodeCompletedCountPort.GetCompletedNodeCountsByZoneIdsAsync(userId, zoneIds)`

## Travel mechanic

1. User picks destination → `PUT /api/map/destination` sets `UserMapProgress.DestinationNodeId` and resolves the edge.
2. Activity logged → `AddDistanceAsync(userId, km)`:
   - Adds km to `DistanceTraveledOnEdge`.
   - If `DistanceTraveledOnEdge >= edge.DistanceKm`: arrive at `DestinationNodeId`, unlock the node (`UserNodeUnlock`), clear the edge, compute `PendingDistanceKm` (overflow).
3. User can immediately set a new destination; pending km auto-applies.

## Endpoints
- `GET /api/map/full?worldZoneId={id}` — full graph view for current zone
- `PUT /api/map/destination` — set next node
- Admin + debug endpoints (see [[Debug Endpoints]])

## Files
- `backend/src/modules/LifeLevel.Modules.Map/`
- `backend/src/LifeLevel.Api/Application/Services/MapService.cs` (orchestration)

## Related
- [[Adventure Map and World]]
- [[WorldZone]]
- [[Adventure.Encounters]]
- [[Adventure.Dungeons]]
- [[Activity]] (credits distance)
