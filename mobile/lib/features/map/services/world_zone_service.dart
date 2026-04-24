import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/world_map_models.dart';
import '../models/world_zone_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorldZoneService — world-level zone map API calls
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown by [WorldZoneService.enterRegion] when the target region's level
/// gate isn't met (backend responds 409 with error code `REGION_LOCKED`).
class RegionLockedException implements Exception {
  final String regionName;
  final int levelRequirement;
  const RegionLockedException({
    required this.regionName,
    required this.levelRequirement,
  });
  @override
  String toString() =>
      'RegionLockedException(regionName: $regionName, levelRequirement: $levelRequirement)';
}

/// Thrown by [WorldZoneService.enterRegion] when the user is already in a
/// different region and the request was sent without `force=true`. Callers
/// should prompt the user and retry with `force: true` on confirm.
class CrossRegionSwitchException implements Exception {
  final String currentRegionName;
  final String destRegionName;
  const CrossRegionSwitchException({
    required this.currentRegionName,
    required this.destRegionName,
  });
  @override
  String toString() =>
      'CrossRegionSwitchException(from: $currentRegionName, to: $destRegionName)';
}

/// Thrown by [WorldZoneService.setDestination] when the target zone is a
/// branch of a crossroads whose sibling was already chosen (backend 409 with
/// error code `PATH_ALREADY_CHOSEN`). The user has to stick with their pick.
class PathAlreadyChosenException implements Exception {
  final String message;
  const PathAlreadyChosenException(this.message);
  @override
  String toString() => 'PathAlreadyChosenException($message)';
}

/// Thrown by [WorldZoneService.openChest] when the user already opened the
/// chest at this zone (backend 409 `CHEST_ALREADY_OPENED`).
class ChestAlreadyOpenedException implements Exception {
  final String message;
  const ChestAlreadyOpenedException(this.message);
  @override
  String toString() => 'ChestAlreadyOpenedException($message)';
}

/// Thrown by [WorldZoneService.setDestination] when the target zone is a
/// crossroads branch but the user is not currently at the parent crossroads
/// (backend 409 `BRANCH_REQUIRES_CROSSROADS_ARRIVAL`). The mobile should
/// gate the CTA upfront so this typically only fires on API misuse.
class BranchRequiresCrossroadsArrivalException implements Exception {
  final String message;
  final String crossroadsName;
  final String crossroadsZoneId;
  const BranchRequiresCrossroadsArrivalException({
    required this.message,
    required this.crossroadsName,
    required this.crossroadsZoneId,
  });
  @override
  String toString() =>
      'BranchRequiresCrossroadsArrivalException($message)';
}

class OpenChestResult {
  final String zoneName;
  final int xp;
  const OpenChestResult({required this.zoneName, required this.xp});
  factory OpenChestResult.fromJson(Map<String, dynamic> json) => OpenChestResult(
        zoneName: json['zoneName'] as String? ?? '',
        xp: (json['xp'] as num?)?.toInt() ?? 0,
      );
}

/// Destination-set response. Returns the number of dungeon floors the user
/// just forfeited by moving away from an in-progress dungeon — mobile uses
/// this to surface a snackbar when the abandon was triggered server-side
/// (e.g. auto-advance during AddDistance).
class SetDestinationResult {
  final int forfeitedFloors;
  const SetDestinationResult({required this.forfeitedFloors});
  factory SetDestinationResult.fromJson(Map<String, dynamic> json) =>
      SetDestinationResult(
        forfeitedFloors: (json['forfeitedFloors'] as num?)?.toInt() ?? 0,
      );
}

class WorldZoneService {
  /// World hub data — list of regions + user + optional active journey.
  /// Backed by the rebuilt `GET /api/map/world` endpoint.
  Future<WorldMapData> getWorldMap() async {
    final response = await ApiClient.instance.get('/map/world');
    return WorldMapData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Region detail — region metadata + ordered node trail + edges.
  /// Backed by `GET /api/map/region/{id}`.
  Future<RegionDetail> getRegionDetail(String regionId) async {
    final response = await ApiClient.instance.get('/map/region/$regionId');
    return RegionDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// Legacy: flat world zone overview. Kept for the local-map MapScreen
  /// which still relies on edges/zones + user progress. New world-hub UI
  /// uses [getWorldMap] / [getRegionDetail] instead.
  Future<WorldFullData> getFullWorld() async {
    final response = await ApiClient.instance.get('/world/full');
    return WorldFullData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SetDestinationResult> setDestination(String destinationZoneId) async {
    try {
      final response = await ApiClient.instance.put(
        '/world/destination',
        data: {'destinationZoneId': destinationZoneId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return SetDestinationResult.fromJson(data);
      }
      return const SetDestinationResult(forfeitedFloors: 0);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        final map = data is Map ? data : const {};
        if (map['error'] == 'PATH_ALREADY_CHOSEN') {
          throw PathAlreadyChosenException(
            map['message'] as String? ?? 'You already chose a different path.',
          );
        }
        if (map['error'] == 'BRANCH_REQUIRES_CROSSROADS_ARRIVAL') {
          throw BranchRequiresCrossroadsArrivalException(
            message: map['message'] as String? ??
                'Reach the crossroads before picking a branch.',
            crossroadsName: map['crossroadsName'] as String? ?? 'the crossroads',
            crossroadsZoneId: map['crossroadsZoneId'] as String? ?? '',
          );
        }
      }
      rethrow;
    }
  }

  /// Open a chest zone the user is currently standing on. One-shot per user.
  Future<OpenChestResult> openChest(String zoneId) async {
    try {
      final response =
          await ApiClient.instance.post('/world/chest/$zoneId/open');
      return OpenChestResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        final map = data is Map ? data : const {};
        if (map['error'] == 'CHEST_ALREADY_OPENED') {
          throw ChestAlreadyOpenedException(
            map['message'] as String? ?? 'You already opened this chest.',
          );
        }
      }
      rethrow;
    }
  }

  /// Enter a dungeon the user is standing on. Idempotent — re-entering an
  /// in-progress run is a no-op on the server side.
  Future<void> enterDungeon(String zoneId) async {
    await ApiClient.instance.post('/world/dungeon/$zoneId/enter');
  }

  /// Fetch per-floor state for the dungeon overlay.
  Future<DungeonState> getDungeonState(String zoneId) async {
    final response = await ApiClient.instance.get('/world/dungeon/$zoneId/state');
    return DungeonState.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> completeZone(String zoneId) async {
    final response = await ApiClient.instance.post('/world/zone/$zoneId/complete');
    return response.data as Map<String, dynamic>;
  }

  Future<void> debugAddDistance(double km) async {
    await ApiClient.instance.post('/world/debug/add-distance', data: {'km': km});
  }

  /// Teleports the user to the entry zone of [regionId]. Pass [force]=true
  /// after the user confirms a cross-region switch.
  ///
  /// Maps backend 409 responses to typed exceptions:
  ///   * `REGION_LOCKED`        → [RegionLockedException]
  ///   * `CROSS_REGION_SWITCH`  → [CrossRegionSwitchException]
  Future<void> enterRegion(String regionId, {bool force = false}) async {
    try {
      await ApiClient.instance.post(
        '/world/region/$regionId/enter',
        queryParameters: {'force': force},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        final map = data is Map ? data : const {};
        final error = map['error'] as String? ?? '';
        if (error == 'CROSS_REGION_SWITCH') {
          throw CrossRegionSwitchException(
            currentRegionName: map['currentRegionName'] as String? ?? '',
            destRegionName: map['destRegionName'] as String? ?? '',
          );
        }
        throw RegionLockedException(
          regionName: map['regionName'] as String? ?? '',
          levelRequirement: map['levelRequirement'] as int? ?? 0,
        );
      }
      rethrow;
    }
  }
}
