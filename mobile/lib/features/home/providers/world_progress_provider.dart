import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../map/models/world_map_models.dart';
import '../../map/models/world_zone_models.dart';
import '../../map/services/world_zone_service.dart';

/// World-level progress for the home portal card. Returns the full zone
/// overview (zones, edges, user progress, character level) via the legacy
/// `/world/full` endpoint that already powers the zone-level map.
final worldProgressProvider = FutureProvider.autoDispose<WorldFullData>(
  (ref) => WorldZoneService().getFullWorld(),
);

/// Rich detail for the region the player's current zone belongs to. Used by
/// the portal to surface ZoneNode-level data (chest reward, dungeon floors,
/// crossroads branches). Resolves to null if the user has no region yet.
final currentRegionDetailProvider =
    FutureProvider.autoDispose<RegionDetail?>((ref) async {
  final world = await ref.watch(worldProgressProvider.future);
  final regionId = world.userProgress.currentRegionId;
  if (regionId == null || regionId.isEmpty) return null;
  return WorldZoneService().getRegionDetail(regionId);
});

/// Per-floor state for a dungeon zone. Lets the home portal render the active
/// or next floor's target activity inline on the dungeon variant. Family on
/// zoneId so the cache is keyed per dungeon and naturally autoDisposed.
final dungeonStateProvider =
    FutureProvider.autoDispose.family<DungeonState?, String>(
  (ref, zoneId) async {
    if (zoneId.isEmpty) return null;
    return WorldZoneService().getDungeonState(zoneId);
  },
);
