import '../../../core/api/api_client.dart';
import '../models/achievement_models.dart';

class AchievementsService {
  final _dio = ApiClient.instance;

  Future<List<AchievementDto>> getAchievements({String? category}) async {
    final res = await _dio.get(
      '/achievements',
      queryParameters: (category != null && category != 'All')
          ? {'category': category}
          : null,
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AchievementDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CheckUnlocksResult> checkUnlocks() async {
    final res = await _dio.post('/achievements/check-unlocks');
    return CheckUnlocksResult.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Reward Roads ──────────────────────────────────────────────────────────

  Future<AchievementRoadsData> getRoads() async {
    final res = await _dio.get('/achievements/roads');
    return AchievementRoadsData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AchievementClaimResult> claim(String achievementId) async {
    final res = await _dio.post('/achievements/$achievementId/claim');
    return AchievementClaimResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AchievementClaimResult> claimAll({String? category}) async {
    final res = await _dio.post(
      '/achievements/claim-all',
      queryParameters: category == null ? null : {'category': category},
    );
    return AchievementClaimResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<StageChestOpenResult> openStageChest(
      String category, String tier) async {
    final res = await _dio.post('/achievements/stages/$category/$tier/open');
    return StageChestOpenResult.fromJson(res.data as Map<String, dynamic>);
  }
}
