import '../../../core/api/api_client.dart';
import '../models/notification_preferences.dart';

class NotificationPreferencesService {
  final _dio = ApiClient.instance;

  Future<NotificationPreferences> getPreferences() async {
    final res = await _dio.get('/notifications/preferences');
    return NotificationPreferences.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final res = await _dio.put(
      '/notifications/preferences',
      data: preferences.toJson(),
    );
    return NotificationPreferences.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }
}
