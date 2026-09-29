import '../../../core/api/api_client.dart';
import '../../integrations/models/integration_models.dart';
import '../models/onboarding_models.dart';

/// Backend calls specific to import-first onboarding.
class OnboardingService {
  final _dio = ApiClient.instance;

  /// Workouts Strava has for the last 30 days (shown on the Connect screen).
  Future<int> previewStrava() async {
    final res = await _dio
        .get('/onboarding/preview', queryParameters: {'source': 'strava'});
    return (res.data as Map<String, dynamic>)['workoutCount'] as int? ?? 0;
  }

  /// Imports the last 30 days at half XP. Strava is pulled server-side;
  /// Health Connect workouts are read on the device and sent here.
  Future<OnboardingImportResult> importHistory({
    required String source,
    List<ExternalActivityDto> activities = const [],
  }) async {
    final res = await _dio.post('/onboarding/import', data: {
      'source': source,
      'activities': activities.map((a) => a.toJson()).toList(),
    });
    return OnboardingImportResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ClassRecommendation> getRecommendation() async {
    final res = await _dio.get('/character/class-recommendation');
    return ClassRecommendation.fromJson(res.data as Map<String, dynamic>);
  }
}
