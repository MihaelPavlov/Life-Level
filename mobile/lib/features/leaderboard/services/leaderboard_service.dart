import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../models/leaderboard_models.dart';

class LeaderboardService {
  final _dio = ApiClient.instance;

  Future<LeaderboardBoard> getBoard(
      LeaderboardScope scope, LeaderboardMetric metric) async {
    final res = await ApiClient.cachedGet('/leaderboard',
        changedArea: 'leaderboard',
        queryParameters: {'scope': scope.name, 'metric': metric.name});
    return LeaderboardBoard.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LeaderboardChest> getChest() async {
    final res = await ApiClient.cachedGet('/leaderboard/chest',
        changedArea: 'leaderboard');
    return LeaderboardChest.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LeaderboardChestOpened> openChest() async {
    try {
      final res = await _dio.post('/leaderboard/chest/open');
      return LeaderboardChestOpened.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiFailure.from(error,
          fallback: 'Could not open the leaderboard chest.');
    }
  }
}
