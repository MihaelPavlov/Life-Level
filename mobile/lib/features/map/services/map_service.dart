import '../../../core/api/api_client.dart';
import '../models/map_models.dart';

class MapService {
  Future<MapFullData> getFullMap() async {
    final response = await ApiClient.instance.get('/map/full');
    return MapFullData.fromJson(response.data);
  }

  Future<void> setDestination(String destinationNodeId) async {
    await ApiClient.instance.put('/map/destination', data: {
      'destinationNodeId': destinationNodeId,
    });
  }

  // ── Debug ──────────────────────────────────────────────────────────────────

  Future<void> debugTeleport(String nodeId) async {
    await ApiClient.instance.post('/map/debug/teleport/$nodeId');
  }

  Future<void> debugAddDistance(double km) async {
    await ApiClient.instance.post('/map/debug/add-distance', data: {'km': km});
  }

  Future<int> debugAdjustLevel(int delta) async {
    final response = await ApiClient.instance.post('/map/debug/adjust-level', data: {'delta': delta});
    return response.data['level'] as int;
  }

  Future<void> debugUnlockNode(String nodeId) async {
    await ApiClient.instance.post('/map/debug/unlock-node/$nodeId');
  }

  Future<void> debugUnlockAll() async {
    await ApiClient.instance.post('/map/debug/unlock-all');
  }

  Future<void> debugResetProgress() async {
    await ApiClient.instance.post('/map/debug/reset-progress');
  }

  Future<int> debugSetXp(int xp) async {
    final response = await ApiClient.instance.post('/map/debug/set-xp', data: {'xp': xp});
    return (response.data['xp'] as num).toInt();
  }
}
