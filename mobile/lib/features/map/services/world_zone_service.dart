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

  Future<void> setDestination(String destinationZoneId) async {
    await ApiClient.instance.put('/world/destination', data: {
      'destinationZoneId': destinationZoneId,
    });
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
