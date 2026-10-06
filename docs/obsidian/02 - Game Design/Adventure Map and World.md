---
tags: [lifelevel, game-design]
aliases: [World Map, Adventure Map, Zones, Travel]
---
# Adventure Map and World

> Two-tier exploration: the **overworld** (WorldZones) and the **dungeon layer** (Map nodes inside each zone). Activity-specific Adventure km fuel overworld travel; dungeon objectives retain real workout distance.

## Two layers, two modules

| Layer | Module | Entities | What it represents |
|-------|--------|----------|---------------------|
| Overworld | [[WorldZone]] | `World`, `WorldZone`, `WorldZoneEdge`, `UserWorldProgress`, `UserZoneUnlock` | Named regions (Forest of Endurance, Mountains of Strength, Ocean of Balance) connected by zone edges. Level-gated. |
| Dungeon | [[Map]] | `MapNode`, `MapEdge`, `UserMapProgress`, `UserNodeUnlock` | Graph of encounter nodes inside a zone: Boss, Chest, DungeonPortal, Crossroads. |

Users arrive at a zone via the overworld, then explore the zone's internal map via [[Adventure.Encounters]] + [[Adventure.Dungeons]].

## Node types

| Type | Owner module | Purpose |
|------|--------------|---------|
| `Boss` | Adventure.Encounters | 7-day timer fight; awards XP on defeat. See [[Boss System]]. |
| `Chest` | Adventure.Encounters | Opens once; awards XP + items. |
| `DungeonPortal` | Adventure.Dungeons | Multi-floor dungeon; XP per floor. |
| `Crossroads` | Adventure.Dungeons | Branching paths — pick one, teleports you to another node. |

## Travel mechanic

1. User picks a **destination** (adjacent zone or node): `PUT /api/map/destination` or `PUT /api/world/destination`.
2. The Activity module converts real distance to **Adventure km** (run/walk/hike ×1, cycling ×0.25, swimming ×4) and sends that value through `IWorldZoneDistancePort.AddDistanceAsync`.
3. When `DistanceTraveledOnEdge >= edge.DistanceKm`: arrive at destination, clear the edge, unlock the node/zone if first visit.
4. First arrival at a new zone awards `zone.TotalXp`.

Adventure km logged without a destination, or left over after an arrival or encounter, are stored in `PendingDistanceKm` and applied to the next selected route.

## Crossroads pass-through

Crossroads zones are **instant** — no distance required to pass through. This matches the design intent of crossroads being decision points, not travel barriers.

## Level gating

- Zones: `LevelRequirement` is a soft gate — enforced via the graph query (zones above your level don't appear as destinations).
- Nodes: `LevelRequirement` — interactions blocked below the threshold.

## Default regions (from CLAUDE.md)

- Forest of Endurance
- Mountains of Strength
- Ocean of Balance

The [[Seeders]] (specifically `WorldSeeder`) populate the World, WorldZones, WorldZoneEdges, MapNodes, MapEdges, Bosses, Chests, DungeonPortals, DungeonFloors, Crossroads, and CrossroadsPaths on first startup.

## MapService stays in composition root

The orchestrating `MapService.GetFullMapAsync` stays in `LifeLevel.Api` (not inside any module) because it loads Boss/Chest/DungeonPortal/Crossroads entities from multiple Adventure modules by `NodeId` lookup — moving it into a module would require a dependency cycle.

## Related
- [[Boss System]]
- [[Map]] (backend module)
- [[WorldZone]] (backend module)
- [[Adventure.Encounters]]
- [[Adventure.Dungeons]]
- [[Feature - Map]] (mobile)
- [[Seeders]]
