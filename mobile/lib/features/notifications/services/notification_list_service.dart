import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../models/notification_list_models.dart';

/// Fetches the user's in-app notification history from
/// `GET /api/notifications` and marks it as read via the controller's
/// `POST /api/notifications/mark-all-read` endpoint.
///
/// Both endpoints are owned by the backend Notifications module (migration
/// 20260417201912_AddNotificationsModule). If the backend is running an
/// older build that does not yet expose the list endpoints, the service
/// returns an empty list instead of surfacing the 404 — this keeps the
/// bell sheet from showing a red error state while the backend catches up.
class NotificationListService {
  NotificationListService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<List<NotificationItem>> list() async {
    try {
      final res = await _dio.get('/notifications');
      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(NotificationItem.fromJson)
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final items = (data['items'] ?? data['notifications']) as List?;
        if (items != null) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(NotificationItem.fromJson)
              .toList();
        }
      }
      return const <NotificationItem>[];
    } on DioException catch (e) {
      // Endpoint not yet deployed → treat as empty rather than crash the UI.
      if (e.response?.statusCode == 404) {
        debugPrint(
          '[NotificationListService] GET /notifications returned 404 — '
          'endpoint pending backend implementation; showing empty list.',
        );
        return const <NotificationItem>[];
      }
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/mark-all-read');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint(
          '[NotificationListService] POST /notifications/mark-all-read '
          'returned 404 — endpoint pending backend implementation.',
        );
        return;
      }
      rethrow;
    }
  }
}
