import '../../../core/api/api_client.dart';
import '../../integrations/models/integration_models.dart';
import '../models/pending_models.dart';

/// Talks to the pending-workout queue. None of these calls reach Strava or
/// Garmin: the queue lives in our database and is filled by their webhooks.
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

  Future<ImportPendingResult> import(List<String> ids) async {
    final res = await ApiClient.instance.post(
      '/integrations/pending/import',
      data: {'ids': ids},
    );
    return ImportPendingResult.fromJson(res.data as Map<String, dynamic>);
  }
}
