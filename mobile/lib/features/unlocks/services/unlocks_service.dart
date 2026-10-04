import '../../../core/api/api_client.dart';
import '../models/unlock_models.dart';

class UnlocksService {
  final _dio = ApiClient.instance;

  Future<UnlocksSnapshot> getUnlocks() async {
    final res = await _dio.get('/unlocks');
    return UnlocksSnapshot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markSeen(String key) => _dio.post('/unlocks/$key/seen');

  /// Returns the coins awarded (0 when the tour was already finished once).
  /// Tours pay coins, never XP, so they can't trigger a level-up mid-queue.
  Future<int> markToured(String key) async {
    final res = await _dio.post('/unlocks/$key/toured');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return (data['coinsAwarded'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
