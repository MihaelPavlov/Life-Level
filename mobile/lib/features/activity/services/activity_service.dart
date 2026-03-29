import '../../../core/api/api_client.dart';
import '../models/activity_models.dart';

class ActivityService {
  final _dio = ApiClient.instance;

  Future<LogActivityResult> logActivity(LogActivityRequest request) async {
    final res = await _dio.post('/activity/log', data: request.toJson());
    return LogActivityResult.fromJson(res.data as Map<String, dynamic>);
  }
}
