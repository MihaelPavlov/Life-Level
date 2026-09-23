import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/login_reward_models.dart';
import '../models/reward_center_models.dart';

class LoginRewardService {
  final _dio = ApiClient.instance;

  Future<LoginRewardStatus> getStatus() async {
    final res = await _dio.get('/login-reward');
    return LoginRewardStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<RewardCenterData> getRewardCenter() async {
    final res = await _dio.get('/rewards');
    return RewardCenterData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> claimMilestone(String period, int threshold) async {
    try {
      await _dio
          .post('/rewards/milestones/${period.toLowerCase()}/$threshold/claim');
    } on DioException catch (e) {
      throw LoginRewardException(_errorMessage(e));
    }
  }

  /// Claims every reached-but-unclaimed milestone for the period in one
  /// call — same "collect everything owed" pattern as the season track's
  /// `claim-available`.
  Future<List<MilestoneClaimResult>> claimAvailableMilestones(
      String period) async {
    try {
      final res = await _dio.post(
          '/rewards/milestones/${period.toLowerCase()}/claim-available');
      final list = res.data as List<dynamic>;
      return list
          .map((e) =>
              MilestoneClaimResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw LoginRewardException(_errorMessage(e));
    }
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
