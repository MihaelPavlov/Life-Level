import '../../core/api/api_client.dart';
import 'models/login_reward_models.dart';

class LoginRewardService {
  final _dio = ApiClient.instance;

  Future<LoginRewardStatus> getStatus() async {
    final res = await _dio.get('/login-reward');
    return LoginRewardStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LoginRewardClaimResult> claimReward() async {
    final res = await _dio.post('/login-reward/claim');
    return LoginRewardClaimResult.fromJson(res.data as Map<String, dynamic>);
  }
}
