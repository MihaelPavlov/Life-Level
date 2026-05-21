import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/login_reward_models.dart';

class LoginRewardService {
  final _dio = ApiClient.instance;

  Future<LoginRewardStatus> getStatus() async {
    final res = await _dio.get('/login-reward');
    return LoginRewardStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LoginRewardClaimResult> claimReward() async {
    try {
      final res = await _dio.post('/login-reward/claim');
      return LoginRewardClaimResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _errorMessage(e);
      if (e.response?.statusCode == 409) {
        throw LoginRewardAlreadyClaimedException(message);
      }
      throw LoginRewardException(message);
    }
  }

  String _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return 'Could not claim daily reward. Please try again.';
  }
}

class LoginRewardException implements Exception {
  final String message;

  const LoginRewardException(this.message);

  @override
  String toString() => message;
}

class LoginRewardAlreadyClaimedException extends LoginRewardException {
  const LoginRewardAlreadyClaimedException(super.message);
}
