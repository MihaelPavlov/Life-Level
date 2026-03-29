import '../../../core/api/api_client.dart';

class CrossroadsService {
  Future<Map<String, dynamic>> choosePath(String crossroadsId, String pathId) async {
    final response = await ApiClient.instance.post(
      '/crossroads/$crossroadsId/choose-path',
      data: {'pathId': pathId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> debugReset(String crossroadsId) async {
    await ApiClient.instance.post('/crossroads/$crossroadsId/debug/reset');
  }
}
