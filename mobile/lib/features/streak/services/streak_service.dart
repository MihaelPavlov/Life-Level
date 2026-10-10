import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../models/streak_models.dart';

class StreakService {
  final _dio = ApiClient.instance;

  Future<StreakData> getStreak() async {
    final res = await ApiClient.cachedGet('/streak', changedArea: 'streak');
    return StreakData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UseShieldResult> useShield() async {
    final res = await _dio.post('/streak/use-shield');
    return UseShieldResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ClaimStreakRewardResult> claimReward() async {
    try {
      final response = await _dio.post('/streak/claim-reward');
      return ClaimStreakRewardResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw StreakException(
          ApiFailure.from(error, fallback: 'Could not claim streak reward.')
              .message);
    }
  }
}

class StreakException implements Exception {
  final String message;
  const StreakException(this.message);

  @override
  String toString() => message;
}
