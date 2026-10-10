import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../integrations/models/integration_models.dart';
import '../models/onboarding_models.dart';

/// Backend calls specific to import-first onboarding.
class OnboardingService {
  final _dio = ApiClient.instance;

  /// Workouts Strava has for the last 30 days (shown on the Connect screen).
  Future<int> previewStrava() async {
    try {
      final res = await _dio
          .get('/onboarding/preview', queryParameters: {'source': 'strava'});
      final data = res.data as Map<String, dynamic>;
      _throwIfErrors(data);
      return data['workoutCount'] as int? ?? 0;
    } on DioException catch (e) {
      throw OnboardingSyncException(_responseMessage(e));
    }
  }

  /// Imports the last 30 days at half XP. Strava is pulled server-side;
  /// Health Connect workouts are read on the device and sent here.
  Future<OnboardingImportResult> importHistory({
    required String source,
    List<ExternalActivityDto> activities = const [],
  }) async {
    try {
      final res = await _dio.post('/onboarding/import', data: {
        'source': source,
        'activities': activities.map((a) => a.toJson()).toList(),
      });
      final data = res.data as Map<String, dynamic>;
      if ((data['imported'] as num? ?? 0) == 0) _throwIfErrors(data);
      return OnboardingImportResult.fromJson(data);
    } on DioException catch (e) {
      throw OnboardingSyncException(_responseMessage(e));
    }
  }

  static void _throwIfErrors(Map<String, dynamic> data) {
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw OnboardingSyncException(errors.first.toString());
    }
  }

  static String _responseMessage(DioException error) {
    return ApiFailure.from(error,
            fallback:
                'Could not reach the workout provider. Check your connection and try again.')
        .message;
  }

  Future<ClassRecommendation> getRecommendation() async {
    final res = await _dio.get('/character/class-recommendation');
    return ClassRecommendation.fromJson(res.data as Map<String, dynamic>);
  }
}

class OnboardingSyncException implements Exception {
  final String message;
  const OnboardingSyncException(this.message);

  @override
  String toString() => message;
}
