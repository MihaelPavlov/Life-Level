import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../integrations/models/integration_models.dart';
import '../models/pending_models.dart';

/// Talks to the pending-workout queue. Manual Strava refresh fetches recent
/// workouts into that same queue; ordinary list calls stay database-only.
class StravaStageException implements Exception {
  final String message;
  const StravaStageException(this.message);
}

class PendingWorkoutsService {
  Future<PendingWorkoutList> list() async {
    final res = await ApiClient.instance.get('/integrations/pending');
    return PendingWorkoutList.fromJson(res.data as Map<String, dynamic>);
  }

  /// Queues workouts read locally from Health Connect / Apple Health and
  /// returns the whole queue.
  Future<PendingWorkoutList> stage(List<ExternalActivityDto> activities) async {
    final res = await ApiClient.instance.post(
      '/integrations/pending/stage',
      data: SyncBatchRequest(activities: activities).toJson(),
    );
    return PendingWorkoutList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PendingWorkoutList> stageStrava() async {
    try {
      final res = await ApiClient.instance.post('/integrations/strava/stage');
      return PendingWorkoutList.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message =
          data is Map<String, dynamic> ? data['error']?.toString() : null;
      throw StravaStageException(
          message ?? 'Could not fetch Strava workouts. Try again.');
    }
  }

  Future<ImportPendingResult> import(List<String> ids) async {
    final res = await ApiClient.instance.post(
      '/integrations/pending/import',
      data: {'ids': ids},
    );
    return ImportPendingResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> acknowledgeRejected(List<String> ids) async {
    if (ids.isEmpty) return;
    await ApiClient.instance.post(
      '/integrations/pending/acknowledge',
      data: {'ids': ids},
    );
  }
}
