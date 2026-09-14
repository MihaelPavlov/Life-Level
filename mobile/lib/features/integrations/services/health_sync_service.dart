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
  static const _stepsPerKm = 1250.0;
  static const _estimatedStepsPerMinute = 100;
  static const _minDailyStepsToImport = 100;

  // WORKOUT internally requests READ_EXERCISE_SESSION + READ_DISTANCE + READ_TOTAL_CALORIES_BURNED.
  // STEPS imports daily movement as Walking activities for internal testing.
  static const _readTypes = [HealthDataType.WORKOUT, HealthDataType.STEPS];

  final _health = Health();

  String get _platformHealthStoreName =>
      Platform.isIOS ? 'Apple Health' : 'Health Connect';

  // ── permissions ───────────────────────────────────────────────────────────

  Future<bool> isPermissionGranted() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    try {
      await _health.configure();
      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        await prefs.setBool(_permissionKey, false);
        return false;
      }

      final granted = await _health.hasPermissions(
            _readTypes,
            permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
          ) ??
          false;
      await prefs.setBool(_permissionKey, granted);
      return granted;
    } catch (e) {
      debugPrint('$_platformHealthStoreName permission check error: $e');
      return prefs.getBool(_permissionKey) ?? false;
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      if (await isPermissionGranted()) return true;

      await _health.configure();
      final available = await _health.isHealthConnectAvailable();
      debugPrint('$_platformHealthStoreName available: $available');
      if (!available) return false;

      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      debugPrint('$_platformHealthStoreName permissions granted: $granted');

      if (!granted && !kIsWeb && Platform.isAndroid) {
        // On MIUI the permission dialog is often blocked — open Health Connect
        // app directly so the user can grant permissions manually.
        debugPrint('Falling back: opening Health Connect app');
        await launchUrl(
          Uri.parse('android-app://com.google.android.apps.healthdata'),
          mode: LaunchMode.externalApplication,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_permissionKey, false);
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionKey, granted);
      return granted;
    } catch (e) {
      debugPrint('$_platformHealthStoreName error: $e');
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

    // ── 1. Verify the platform health store is available & permissions are still valid ──
    try {
      await _health.configure();
      final available = await _health.isHealthConnectAvailable();
      debugPrint(
          '[HealthSync] $_platformHealthStoreName available: $available');
      if (!available) {
        return SyncResult(imported: 0, skipped: 0, errors: [
          '$_platformHealthStoreName is not available on this device.'
        ]);
      }

      final hasPerms = await _health.hasPermissions(
            _readTypes,
            permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
          ) ??
          false;
      debugPrint('[HealthSync] permissions check: $hasPerms');
      if (!hasPerms) {
        // Clear cached flag so UI shows "Connect" again
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_permissionKey, false);
        return SyncResult(imported: 0, skipped: 0, errors: [
          '$_platformHealthStoreName permissions were revoked. Please reconnect.'
        ]);
      }
    } catch (e) {
      debugPrint('[HealthSync] permission check error: $e');
      // Non-fatal — proceed with the sync attempt anyway
    }

    // ── 2. Query Health Connect ─────────────────────────────────────────────
    // Always look back at least 30 days to catch workouts logged before first sync
    final since = DateTime.now().toUtc().subtract(const Duration(days: 30));
    final now = DateTime.now().toUtc();

    debugPrint('[HealthSync] querying $since → $now');

    List<HealthDataPoint> dataPoints;
    try {
      dataPoints = await _health.getHealthDataFromTypes(
        startTime: since,
        endTime: now,
        types: _readTypes,
      );
    } catch (e) {
      debugPrint('[HealthSync] ERROR reading health data: $e');
      return SyncResult(
          imported: 0,
          skipped: 0,
          errors: ['Failed to read Health Connect data: $e']);
    }

    debugPrint('[HealthSync] raw data points: ${dataPoints.length}');
    for (final p in dataPoints) {
      debugPrint(
          '[HealthSync]   point: type=${p.typeString} from=${p.dateFrom} to=${p.dateTo} '
          'value=${p.value.runtimeType} source=${p.sourceName}');
    }

    final workouts = _health
        .removeDuplicates(dataPoints)
        .where((p) => p.value is WorkoutHealthValue)
        .toList();

    debugPrint('[HealthSync] filtered workouts: ${workouts.length}');

    final provider = Platform.isIOS
        ? IntegrationProviders.healthKit
        : IntegrationProviders.healthConnect;
    final prefix = Platform.isIOS ? 'healthkit' : 'healthconnect';

    final activities = <ExternalActivityDto>[];
    for (final point in workouts) {
      final workout = point.value as WorkoutHealthValue;
      final duration = point.dateTo.difference(point.dateFrom).inMinutes;
      debugPrint('[HealthSync] workout: type=${workout.workoutActivityType} '
          'duration=${duration}min dist=${workout.totalDistance}m '
          'cal=${workout.totalEnergyBurned} uuid=${point.uuid}');
      if (duration <= 0) {
        debugPrint('[HealthSync]   skipping — zero duration');
        continue;
      }

      final activityType =
          ActivityTypeMapper.fromHealthConnect(workout.workoutActivityType);
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

    activities.addAll(await _buildDailyStepActivities(
      provider: provider,
      prefix: prefix,
    ));

    if (activities.isEmpty) {
      await _saveLastSyncTime(now);
      return const SyncResult.empty();
    }

    final result = await _postBatch(SyncBatchRequest(activities: activities));
    await _saveLastSyncTime(now);
    return result;
  }

  Future<List<ExternalActivityDto>> _buildDailyStepActivities({
    required String provider,
    required String prefix,
  }) async {
    final activities = <ExternalActivityDto>[];
    final localNow = DateTime.now();
    final firstDay = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    ).subtract(const Duration(days: 6));

    for (var day = firstDay;
        !day.isAfter(localNow);
        day = day.add(const Duration(days: 1))) {
      final start = DateTime(day.year, day.month, day.day);
      final nextDay = start.add(const Duration(days: 1));
      final end = nextDay.isAfter(localNow) ? localNow : nextDay;
      if (!end.isAfter(start)) continue;

      int? steps;
      try {
        steps = await _health.getTotalStepsInInterval(
          start,
          end,
          includeManualEntry: false,
        );
      } catch (e) {
        debugPrint('[HealthSync] ERROR reading steps for $start: $e');
        continue;
      }

      final totalSteps = steps ?? 0;
      if (totalSteps < _minDailyStepsToImport) {
        debugPrint('[HealthSync] skipping daily steps $start: $totalSteps');
        continue;
      }

      final dateKey = _dateKey(start);
      final distanceKm = totalSteps / _stepsPerKm;
      final durationMinutes =
          (totalSteps / _estimatedStepsPerMinute).round().clamp(10, 240);

      debugPrint('[HealthSync] daily steps $dateKey: steps=$totalSteps '
          'distanceKm=$distanceKm duration=$durationMinutes');

      activities.add(ExternalActivityDto(
        provider: provider,
        externalId: '$prefix:steps:$dateKey',
        activityType: 'Walking',
        durationMinutes: durationMinutes,
        distanceKm: distanceKm,
        performedAt: start.toUtc(),
      ));
    }

    return activities;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<SyncResult> _postBatch(SyncBatchRequest request) async {
    debugPrint(
        '[HealthSync] posting ${request.activities.length} activities to backend');
    try {
      final response = await ApiClient.instance.post(
        '/integrations/health/sync',
        data: request.toJson(),
      );
      final result = SyncResult.fromJson(response.data as Map<String, dynamic>);
      debugPrint(
          '[HealthSync] backend response: imported=${result.imported} skipped=${result.skipped} errors=${result.errors}');
      return result;
    } catch (e) {
      debugPrint('[HealthSync] ERROR posting to backend: $e');
      return SyncResult(
          imported: 0, skipped: 0, errors: ['Backend sync failed: $e']);
    }
  }
}
