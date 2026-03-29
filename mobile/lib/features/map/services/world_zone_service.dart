import '../../../core/api/api_client.dart';
import '../models/world_zone_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorldZoneService — world-level zone map API calls
// ─────────────────────────────────────────────────────────────────────────────

class WorldZoneService {
  Future<WorldFullData> getFullWorld() async {
    final response = await ApiClient.instance.get('/world/full');
    return WorldFullData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> setDestination(String destinationZoneId) async {
    await ApiClient.instance.put('/world/destination', data: {
      'destinationZoneId': destinationZoneId,
    });
  }

  // ── Debug ──────────────────────────────────────────────────────────────────

  Future<void> debugAddDistance(double km) async {
    await ApiClient.instance
        .post('/world/debug/add-distance', data: {'km': km});
  }
}
