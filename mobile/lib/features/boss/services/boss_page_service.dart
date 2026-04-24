import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/boss_damage_history.dart';
import '../models/boss_list_item.dart';

class BossPageService {
  Future<List<BossListItem>> getAllBosses() async {
    final response = await ApiClient.instance.get('/boss');
    final list = response.data as List;
    return list
        .map((j) => BossListItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Per-activity damage list for a boss the user is currently fighting.
  /// Backend computes the rows on read from activities logged between
  /// `UserBossState.StartedAt` and `DefeatedAt ?? now`. Newest first.
  /// Returns an empty list when the user hasn't engaged the boss yet
  /// (backend returns 404, which we surface as empty for a simpler UI).
  Future<List<BossDamageHistoryItem>> getDamageHistory(String bossId) async {
    try {
      final response =
          await ApiClient.instance.get('/boss/$bossId/damage-history');
      final list = (response.data as List?) ?? const [];
      return list
          .map((e) => BossDamageHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // 404 (no UserBossState) → treat as empty list so the UI renders
      // the default "no hits yet" hint instead of an error. Real failures
      // (5xx, network) still bubble up.
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }
}
