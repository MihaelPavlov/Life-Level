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
}
