---
tags: [lifelevel, mobile]
aliases: [Map Feature, World Map, Map Screen]
---
# Feature — Map

> Two map screens: **MapScreen** (dungeon-layer — nodes inside current zone) and **WorldMapScreen** (overworld — zones at the world level). Both use CustomPainter for pinch-zoomable canvases.

## Files

```
lib/features/map/
├── map_screen.dart            ← dungeon layer
├── world_map_screen.dart      ← overworld layer
├── world_map_models.dart
├── world_map_data.dart        ← static zone definitions (UI only)
├── world_map_painter.dart     ← CustomPainter for zone nodes
├── world_map_detail_sheet.dart ← zone info bottom sheet
├── models/
│   └── map_node_models.dart
├── services/
│   └── map_service.dart
└── widgets/
    ├── boss_node_sheet.dart
    ├── chest_node_sheet.dart
    ├── dungeon_node_sheet.dart
    ├── crossroads_node_sheet.dart
    └── node_detail_sheet.dart
```

## MapScreen

Dungeon-layer canvas. Displays all nodes in the current zone.

- Renders via `CustomPainter`: zone nodes, edges with distance labels, character current position, destination marker
- Interactions:
  - Pinch-zoom / pan via `TransformationController`
  - Tap node → opens appropriate `NodeDetailSheet` (Boss / Chest / Dungeon / Crossroads / generic)
- Listens to `MapTabNotifier` → reloads on tab switch
- Listens to `LevelUpNotifier` → reloads (newly-unlocked zones)
- Admin-only debug panel: teleport, add-distance, adjust-level, unlock, reset

## WorldMapScreen

Overworld canvas. Opened as a full-screen modal from the radial FAB's "World" item.

- Renders 5+ world regions (Forest of Endurance, Mountains of Strength, Ocean of Balance, etc.)
- Tap region → zoom into its internal `MapScreen`
- Shows zones completed / current / locked

## Models

```dart
class MapFullData {
  List<MapNode> nodes;
  List<MapConnection> connections;
  UserProgress userProgress;
}

class MapNode {
  String id, name, emoji;
  double x, y;
  String nodeType;   // 'Zone' | 'Boss' | 'Chest' | 'Dungeon' | 'Crossroads'
  bool isAccessible, isOnPath, isCompleted;
  DateTime? discoveredAt, completedAt;
}

class UserProgress {
  double currentX, currentY;
  double totalDistanceTraveled;
  String? destinationNodeId;
  List<String> completedNodeIds;
}

class WorldZoneDto {
  String id, name, region, emoji;
  List<MapNode> nodes;
  int nodesCompleted, totalNodes;
  bool isCompleted;
}
```

## MapService

```dart
Future<MapFullData> getFullMap({String? worldZoneId});  // GET /api/map/full
Future<void> setDestination(String nodeId);             // PUT /api/map/destination
// Admin:
Future<void> debugTeleport(String nodeId);
Future<void> debugAddDistance(double km);
Future<void> debugAdjustLevel(int delta);
Future<void> debugUnlockNode(String nodeId);
Future<void> debugUnlockAll();
Future<void> debugResetProgress();
Future<void> debugSetXp(int xp);
```

## Node detail sheets

Each node type has a dedicated bottom sheet showing lore + actions:
- `BossNodeSheet` — "Fight boss" action
- `ChestNodeSheet` — "Open chest" action
- `DungeonNodeSheet` — "Enter dungeon" action
- `CrossroadsNodeSheet` — path selector
- `NodeDetailSheet` — generic fallback

## Related
- [[Adventure Map and World]]
- [[Map]] (backend)
- [[WorldZone]] (backend)
- [[Adventure.Encounters]] (boss + chest sheets)
- [[Adventure.Dungeons]] (dungeon + crossroads sheets)
- [[Feature - Boss]] (boss battle flow)
