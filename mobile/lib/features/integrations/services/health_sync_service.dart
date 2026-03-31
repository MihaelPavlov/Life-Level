import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../models/integration_models.dart';
import '../mappers/activity_type_mapper.dart';

class HealthSyncService {
  static const _lastSyncKey = 'health_last_sync_ms';
  static const _permissionKey = 'health_permission_granted';

  // WORKOUT internally requests READ_EXERCISE_SESSION + READ_DISTANCE + READ_TOTAL_CALORIES_BURNED
  static const _readTypes = [HealthDataType.WORKOUT];

  final _health = Health();

  // ── permissions ───────────────────────────────────────────────────────────

  Future<bool> isPermissionGranted() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      await _health.configure();
      final available = await _health.isHealthConnectAvailable();
      debugPrint('Health Connect available: $available');
      if (!available) return false;

      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      debugPrint('Health Connect permissions granted: $granted');

      if (!granted && !kIsWeb && Platform.isAndroid) {
        // On MIUI the permission dialog is often blocked — open Health Connect
        // app directly so the user can grant permissions manually.
        debugPrint('Falling back: opening Health Connect app');
        await launchUrl(
          Uri.parse('android-app://com.google.android.apps.healthdata'),
          mode: LaunchMode.externalApplication,
        );
        // Re-check after user returns from Health Connect
        final recheckGranted = await _health.hasPermissions(
          _readTypes,
          permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
        ) ?? false;
        debugPrint('Recheck permissions granted: $recheckGranted');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_permissionKey, recheckGranted);
        return recheckGranted;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionKey, granted);
      return granted;
    } catch (e) {
      debugPrint('Health Connect error: $e');
      return false;
    }
  }

  // ── last sync time ────────────────────────────────────────────────────────

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  // ── sync ──────────────────────────────────────────────────────────────────

  Future<SyncResult> syncRecentWorkouts() async {
    if (kIsWeb) return const SyncResult.empty();

    final lastSync = await getLastSyncTime();
    final since = lastSync ?? DateTime.now().toUtc().subtract(const Duration(days: 30));
    final now = DateTime.now().toUtc();

    List<HealthDataPoint> dataPoints;
    try {
      dataPoints = await _health.getHealthDataFromTypes(
        startTime: since,
        endTime: now,
        types: _readTypes,
      );
    } catch (e) {
      return SyncResult(imported: 0, skipped: 0, errors: [e.toString()]);
    }

    final workouts = _health
        .removeDuplicates(dataPoints)
        .where((p) => p.value is WorkoutHealthValue)
        .toList();

    if (workouts.isEmpty) {
      await _saveLastSyncTime(now);
      return const SyncResult.empty();
    }

    final provider = Platform.isIOS ? IntegrationProviders.healthKit : IntegrationProviders.healthConnect;
    final prefix = Platform.isIOS ? 'healthkit' : 'healthconnect';

    final activities = <ExternalActivityDto>[];
    for (final point in workouts) {
      final workout = point.value as WorkoutHealthValue;
      final duration = point.dateTo.difference(point.dateFrom).inMinutes;
      if (duration <= 0) continue;

      final activityType = ActivityTypeMapper.fromHealthConnect(workout.workoutActivityType);
      final distanceKm = workout.totalDistance != null
          ? workout.totalDistance! / 1000.0
          : null;
      final calories = workout.totalEnergyBurned?.toInt();

      activities.add(ExternalActivityDto(
        provider: provider,
        externalId: '$prefix:${point.uuid}',
        activityType: activityType,
        durationMinutes: duration,
        distanceKm: distanceKm,
        calories: calories,
        performedAt: point.dateFrom.toUtc(),
      ));
    }

    if (activities.isEmpty) {
      await _saveLastSyncTime(now);
      return const SyncResult.empty();
    }

    final result = await _postBatch(SyncBatchRequest(activities: activities));
    await _saveLastSyncTime(now);
    return result;
  }

  Future<SyncResult> _postBatch(SyncBatchRequest request) async {
    try {
      final response = await ApiClient.instance.post(
        '/integrations/health/sync',
        data: request.toJson(),
      );
      return SyncResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return SyncResult(imported: 0, skipped: 0, errors: [e.toString()]);
    }
  }
}
