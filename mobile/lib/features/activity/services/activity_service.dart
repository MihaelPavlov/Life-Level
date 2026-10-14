import '../../../core/api/api_client.dart';
import '../models/activity_models.dart';
import '../tracking/tracked_session_models.dart';

class ActivityService {
  final _dio = ApiClient.instance;

  Future<List<TrackedSessionDto>> getTrackedSessions() async {
    final res = await _dio.get('/activity/tracked-sessions');
    return (res.data as List<dynamic>)
        .map((item) =>
            TrackedSessionDto.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<LogActivityResult> logActivity(LogActivityRequest request,
      {String? operationId}) async {
    final res = await _dio.post('/activity/log',
        data: request.toJson(),
        options: operationId == null
            ? null
            : ApiClient.mutationOptions(operationId));
    return LogActivityResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ActivityHistoryDto>> getHistory() async {
    final res = await _dio.get('/activity/history');
    return (res.data as List<dynamic>)
        .map((j) => ActivityHistoryDto.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ActivitySummary> getSummary() async {
    final res = await _dio.get('/activity/summary');
    return ActivitySummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ActivityCalendar> getCalendar({int days = 364}) async {
    final res =
        await _dio.get('/activity/calendar', queryParameters: {'days': days});
    return ActivityCalendar.fromJson(res.data as Map<String, dynamic>);
  }
}
