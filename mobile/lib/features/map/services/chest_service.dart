import '../../../core/api/api_client.dart';

class ChestService {
  Future<Map<String, dynamic>> collect(String chestId) async {
    final response = await ApiClient.instance.post('/chest/$chestId/collect');
    return response.data as Map<String, dynamic>;
  }

  Future<void> debugReset(String chestId) async {
    await ApiClient.instance.post('/chest/$chestId/debug/reset');
  }
}
