import 'dart:async';

import '../api/api_client.dart';

class ClientExperienceService {
  ClientExperienceService._();
  static final instance = ClientExperienceService._();

  static const _shippedInstantFeatures = {
    'stats',
    'rewards',
    'streakSeason',
    'achievementsEquipment',
    'map',
    'guild',
    'modes',
    'shop',
    'talents',
    'activity',
    'persistentCache',
  };
  final Map<String, bool> _flags = {};
  final List<Map<String, Object?>> _events = [];
  Timer? _flushTimer;
  bool _loadStarted = false;

  bool enabled(String feature, {bool fallback = false}) =>
      _flags[feature] ??
      (_loadStarted && _shippedInstantFeatures.contains(feature) || fallback);

  Future<void> load() async {
    // Close the startup race synchronously. Remote config replaces these
    // shipped defaults as soon as it arrives and remains the session kill
    // switch. Screens mounted outside the app shell (including tests) keep
    // their explicit fallback behaviour.
    _loadStarted = true;
    ApiClient.persistentCacheEnabled = true;
    try {
      final response =
          await ApiClient.instance.get('/client-experience/config');
      final data = response.data as Map<String, dynamic>;
      final flags = data['flags'] as Map<String, dynamic>? ?? const {};
      _flags
        ..clear()
        ..addAll(flags.map((key, value) => MapEntry(key, value == true)));
      ApiClient.persistentCacheEnabled =
          enabled('persistentCache', fallback: false);
    } catch (_) {
      // A config outage must not make core gameplay unavailable.
    }
  }

  void record({
    required String name,
    required String feature,
    required String outcome,
    int? durationMs,
    String? operationId,
  }) {
    _events.add({
      'name': name,
      'feature': feature,
      'outcome': outcome,
      'durationMs': durationMs,
      'operationId': operationId,
    });
    if (_events.length >= 20) {
      unawaited(flush());
    } else {
      _flushTimer ??= Timer(const Duration(seconds: 10), flush);
    }
  }

  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_events.isEmpty) return;
    final batch = List<Map<String, Object?>>.from(_events);
    _events.clear();
    try {
      await ApiClient.instance
          .post('/client-experience/events', data: {'events': batch});
    } catch (_) {
      // Telemetry is best effort and never blocks gameplay.
    }
  }
}
