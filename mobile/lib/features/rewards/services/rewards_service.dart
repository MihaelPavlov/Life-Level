import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/rewards_models.dart';

class RewardsService {
  final _dio = ApiClient.instance;

  Future<RewardCenterData> getRewardCenter() async {
    final res = await _dio.get('/rewards');
    return RewardCenterData.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> claimMilestone(String period, int threshold) async {
    try {
      await _dio
          .post('/rewards/milestones/${period.toLowerCase()}/$threshold/claim');
    } on DioException catch (e) {
      throw RewardsException(_errorMessage(e));
    }
  }

  Future<TaskRewardsClaimResult> claimAvailableTaskRewards(
      String period) async {
    try {
      final res = await _dio
          .post('/rewards/tasks/${period.toLowerCase()}/claim-available');
      return TaskRewardsClaimResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw RewardsException(_errorMessage(e));
    }
  }

  /// Claims every reached-but-unclaimed milestone for the period in one
  /// call — same "collect everything owed" pattern as the season track's
  /// `claim-available`.
  Future<List<MilestoneClaimResult>> claimAvailableMilestones(
      String period) async {
    try {
      final res = await _dio
          .post('/rewards/milestones/${period.toLowerCase()}/claim-available');
      final list = res.data as List<dynamic>;
      return list
          .map((e) => MilestoneClaimResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw RewardsException(_errorMessage(e));
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
    return 'Could not claim reward. Please try again.';
  }
}

class RewardsException implements Exception {
  final String message;

  const RewardsException(this.message);

  @override
  String toString() => message;
}
