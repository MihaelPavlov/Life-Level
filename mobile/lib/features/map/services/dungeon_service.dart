import '../../../core/api/api_client.dart';

class DungeonService {
  Future<void> enter(String dungeonId) async {
    await ApiClient.instance.post('/dungeon/$dungeonId/enter');
  }

  Future<Map<String, dynamic>> completeFloor(String dungeonId, int floorNumber) async {
    final response = await ApiClient.instance.post(
      '/dungeon/$dungeonId/complete-floor',
      data: {'floorNumber': floorNumber},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> debugSetFloor(String dungeonId, int floor) async {
    await ApiClient.instance.post('/dungeon/$dungeonId/debug/set-floor', data: {'floor': floor});
  }

  Future<void> debugReset(String dungeonId) async {
    await ApiClient.instance.post('/dungeon/$dungeonId/debug/reset');
  }
}
