import '../../../core/api/api_client.dart';
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
    final res = await _dio.post('/leaderboard/chest/open');
    return LeaderboardChestOpened.fromJson(res.data as Map<String, dynamic>);
  }
}
