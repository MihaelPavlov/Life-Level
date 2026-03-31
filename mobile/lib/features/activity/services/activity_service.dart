import '../../../core/api/api_client.dart';
import '../models/activity_models.dart';

class ActivityService {
  final _dio = ApiClient.instance;

  Future<LogActivityResult> logActivity(LogActivityRequest request) async {
    final res = await _dio.post('/activity/log', data: request.toJson());
    return LogActivityResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ActivityHistoryDto>> getHistory() async {
    final res = await _dio.get('/activity/history');
    return (res.data as List<dynamic>)
        .map((j) => ActivityHistoryDto.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
