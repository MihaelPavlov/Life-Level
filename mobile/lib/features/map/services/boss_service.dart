import '../../../core/api/api_client.dart';

class BossService {
  Future<void> activateFight(String bossId) async {
    await ApiClient.instance.post('/boss/$bossId/activate');
  }

  Future<Map<String, dynamic>> dealDamage(String bossId, int damage) async {
    final response = await ApiClient.instance.post(
      '/boss/$bossId/damage',
      data: {'damage': damage},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> dealActivityDamage(
    String bossId, {
    required String activityType,
    required int durationMinutes,
    required double distanceKm,
    required int calories,
  }) async {
    final response = await ApiClient.instance.post(
      '/boss/$bossId/damage/activity',
      data: {
        'activityType': activityType,
        'durationMinutes': durationMinutes,
        'distanceKm': distanceKm,
        'calories': calories,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Debug ──────────────────────────────────────────────────────────────────

  Future<void> debugSetHp(String bossId, int hp) async {
    await ApiClient.instance.post('/boss/$bossId/debug/set-hp', data: {'hp': hp});
  }

  Future<void> debugForceDefeat(String bossId) async {
    await ApiClient.instance.post('/boss/$bossId/debug/force-defeat');
  }

  Future<void> debugForceExpire(String bossId) async {
    await ApiClient.instance.post('/boss/$bossId/debug/force-expire');
  }

  Future<void> debugReset(String bossId) async {
    await ApiClient.instance.post('/boss/$bossId/debug/reset');
  }
}
