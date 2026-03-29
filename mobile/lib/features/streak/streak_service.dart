import '../../core/api/api_client.dart';
import 'models/streak_models.dart';

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
}
