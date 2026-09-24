import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/streak_models.dart';

class StreakService {
  final _dio = ApiClient.instance;

  Future<StreakData> getStreak() async {
    final res = await _dio.get('/streak');
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
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        throw StreakException(data['error'] as String);
      }
      throw const StreakException('Could not claim streak reward.');
    }
  }
}

class StreakException implements Exception {
  final String message;
  const StreakException(this.message);

  @override
  String toString() => message;
}
