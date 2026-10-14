import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:geolocator_apple/geolocator_apple.dart' as apple;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../models/activity_models.dart';

final workoutTrackerProvider = ChangeNotifierProvider<WorkoutTracker>((ref) {
  final tracker = WorkoutTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});

class TrackedWorkout {
  final String id;
  final ActivityType type;
  final DateTime startedAt;
  DateTime? resumedAt;
  DateTime? endedAt;
  int accumulatedSeconds;
  double distanceMeters;
  int gpsSamples;
  int gpsCoveredSeconds;
  double? lastLatitude;
  double? lastLongitude;
  double? lastAccuracy;
  DateTime? lastFixAt;
  DateTime? distanceAnchorAt;

  TrackedWorkout({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.resumedAt,
    this.endedAt,
    this.accumulatedSeconds = 0,
    this.distanceMeters = 0,
    this.gpsSamples = 0,
    this.gpsCoveredSeconds = 0,
    this.lastLatitude,
    this.lastLongitude,
    this.lastAccuracy,
    this.lastFixAt,
    this.distanceAnchorAt,
  });

  bool get isRunning => resumedAt != null;
  bool get usesGps => const {
        ActivityType.running,
        ActivityType.walking,
        ActivityType.hiking,
        ActivityType.cycling,
      }.contains(type);

  int get activeSeconds =>
      accumulatedSeconds +
      (resumedAt == null
          ? 0
          : DateTime.now()
              .toUtc()
              .difference(resumedAt!)
              .inSeconds
              .clamp(0, 86400));

  Map<String, dynamic> toJson() => {
        'sessionId': id,
        'type': type.apiValue,
        'startedAtUtc': startedAt.toIso8601String(),
        'endedAtUtc': endedAt?.toIso8601String(),
        'resumedAt': resumedAt?.toIso8601String(),
        'activeSeconds': endedAt == null ? accumulatedSeconds : activeSeconds,
        'distanceMeters': distanceMeters,
        'gpsSampleCount': gpsSamples,
        'gpsCoveredSeconds': gpsCoveredSeconds,
        'lastLatitude': lastLatitude,
        'lastLongitude': lastLongitude,
        'lastAccuracy': lastAccuracy,
        'lastFixAt': lastFixAt?.toIso8601String(),
        'distanceAnchorAt': distanceAnchorAt?.toIso8601String(),
      };

  Map<String, dynamic> toApiJson() => {
        'sessionId': id,
        'type': type.apiValue,
        'startedAtUtc': startedAt.toIso8601String(),
        'endedAtUtc': endedAt?.toIso8601String(),
        'activeSeconds': accumulatedSeconds,
        'distanceMeters': distanceMeters,
        'gpsSampleCount': gpsSamples,
        'gpsCoveredSeconds': gpsCoveredSeconds.clamp(0, accumulatedSeconds),
      };

  factory TrackedWorkout.fromJson(Map<String, dynamic> json) => TrackedWorkout(
        id: json['sessionId'] as String,
        type: activityTypeFromApiValue(json['type'] as String)!,
        startedAt: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
        resumedAt: json['resumedAt'] == null
            ? null
            : DateTime.parse(json['resumedAt'] as String).toUtc(),
        endedAt: json['endedAtUtc'] == null
            ? null
            : DateTime.parse(json['endedAtUtc'] as String).toUtc(),
        accumulatedSeconds: (json['activeSeconds'] as num).toInt(),
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        gpsSamples: (json['gpsSampleCount'] as num).toInt(),
        gpsCoveredSeconds: (json['gpsCoveredSeconds'] as num?)?.toInt() ?? 0,
        lastLatitude: (json['lastLatitude'] as num?)?.toDouble(),
        lastLongitude: (json['lastLongitude'] as num?)?.toDouble(),
        lastAccuracy: (json['lastAccuracy'] as num?)?.toDouble(),
        lastFixAt: json['lastFixAt'] == null
            ? null
            : DateTime.parse(json['lastFixAt'] as String).toUtc(),
        distanceAnchorAt: json['distanceAnchorAt'] == null
            ? (json['lastFixAt'] == null
                ? null
                : DateTime.parse(json['lastFixAt'] as String).toUtc())
            : DateTime.parse(json['distanceAnchorAt'] as String).toUtc(),
      );

  /// Count a fix for GPS coverage, but keep the distance anchor until motion
  /// exceeds GPS uncertainty. Frequent short strides then accumulate.
  bool recordPosition(Position fix) {
    if (!isRunning ||
        !usesGps ||
        fix.isMocked ||
        fix.accuracy > 35 ||
        fix.accuracy < 0) {
      return false;
    }
    final at = fix.timestamp.toUtc();
    if (at.isBefore(resumedAt!)) return false;
    final previousAt = lastFixAt;
    if (previousAt != null && !at.isAfter(previousAt)) return false;
    final fixGapSeconds = previousAt == null
        ? 0.0
        : at.difference(previousAt).inMilliseconds / 1000.0;
    if (fixGapSeconds > 0 && fixGapSeconds <= 60) {
      gpsCoveredSeconds += fixGapSeconds.round();
    }

    var resetAnchor = lastLatitude == null ||
        lastLongitude == null ||
        distanceAnchorAt == null ||
        fixGapSeconds > 60;
    if (!resetAnchor) {
      final anchorSeconds =
          at.difference(distanceAnchorAt!).inMilliseconds / 1000.0;
      final meters = Geolocator.distanceBetween(
          lastLatitude!, lastLongitude!, fix.latitude, fix.longitude);
      final maxSpeed = type == ActivityType.cycling
          ? 20.0
          : type == ActivityType.running
              ? 9.0
              : 4.5;
      final noiseFloor = (lastAccuracy ?? fix.accuracy) > fix.accuracy
          ? lastAccuracy!
          : fix.accuracy;
      if (anchorSeconds > 0 && meters / anchorSeconds > maxSpeed) {
        resetAnchor = true;
      } else if (meters >= (noiseFloor * 1.2).clamp(5.0, 40.0)) {
        distanceMeters += meters;
        resetAnchor = true;
      }
    }
    if (resetAnchor) {
      lastLatitude = fix.latitude;
      lastLongitude = fix.longitude;
      lastAccuracy = fix.accuracy;
      distanceAnchorAt = at;
    }
    lastFixAt = at;
    gpsSamples++;
    return true;
  }
}

class TrackedWorkoutResult {
  final bool gpsMeasured;
  final LogActivityResult? reward;
  const TrackedWorkoutResult({required this.gpsMeasured, this.reward});

  factory TrackedWorkoutResult.fromJson(Map<String, dynamic> json) =>
      TrackedWorkoutResult(
        gpsMeasured: json['gpsMeasured'] == true,
        reward: json['reward'] is Map
            ? LogActivityResult.fromJson(
                Map<String, dynamic>.from(json['reward'] as Map))
            : null,
      );
}

class WorkoutTracker extends ChangeNotifier {
  static const _activeKey = 'lifelevel.tracker.active.v1';
  static const _pendingKey = 'lifelevel.tracker.pending.v1';
  String _storageScope = 'signed-out';
  String get _scopedActiveKey => '$_activeKey.$_storageScope';
  String get _scopedPendingKey => '$_pendingKey.$_storageScope';
  TrackedWorkout? current;
  bool ready = false;
  bool submitting = false;
  bool gpsAvailable = false;
  String? gpsMessage;
  String? error;
  StreamSubscription<Position>? _positions;
  final List<TrackedWorkout> _pending = [];
  List<TrackedWorkout> get pendingSessions => List.unmodifiable(_pending);
  Future<void> _activeWrite = Future<void>.value();

  WorkoutTracker() {
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final token = await ApiClient.getToken();
      if (token == null) throw StateError('Sign in before tracking.');
      final parts = token.split('.');
      final claims = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, dynamic>;
      _storageScope = (claims[
              'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          claims['sub'] ??
          claims['nameid']) as String;
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getString(_scopedActiveKey);
      if (active != null) {
        current =
            TrackedWorkout.fromJson(jsonDecode(active) as Map<String, dynamic>);
        // A killed process cannot guarantee continuous samples. Preserve the
        // last saved interval and ask the user to resume explicitly.
        if (current!.resumedAt != null) {
          final stoppedAt = current!.usesGps && current!.lastFixAt != null
              ? current!.lastFixAt!
              : DateTime.now().toUtc();
          current!.accumulatedSeconds += stoppedAt
              .difference(current!.resumedAt!)
              .inSeconds
              .clamp(0, 86400);
          current!.resumedAt = null;
        }
      }
      final pending = prefs.getStringList(_scopedPendingKey) ?? const [];
      _pending.addAll(pending.map((s) =>
          TrackedWorkout.fromJson(jsonDecode(s) as Map<String, dynamic>)));
      if (current != null) await _saveActive();
      unawaited(retryPending());
    } catch (_) {
      error = 'Could not restore the previous workout.';
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> start(ActivityType type) async {
    if (!ready || _storageScope == 'signed-out') {
      throw StateError('Workout tracking is not ready.');
    }
    if (current != null) throw StateError('Finish the current workout first.');
    final now = DateTime.now().toUtc();
    current = TrackedWorkout(
        id: const Uuid().v4(), type: type, startedAt: now, resumedAt: now);
    error = null;
    await _saveActive();
    notifyListeners();
    if (current!.usesGps) await _startGps();
  }

  Future<void> pause() async {
    final session = current;
    if (session == null || !session.isRunning) return;
    session.accumulatedSeconds = session.activeSeconds;
    session.resumedAt = null;
    session.lastLatitude = null;
    session.lastLongitude = null;
    session.lastAccuracy = null;
    session.lastFixAt = null;
    session.distanceAnchorAt = null;
    await _stopGps();
    await _saveActive();
    notifyListeners();
  }

  Future<void> resume() async {
    final session = current;
    if (session == null || session.isRunning) return;
    session.resumedAt = DateTime.now().toUtc();
    session.lastLatitude = null;
    session.lastLongitude = null;
    session.lastAccuracy = null;
    session.lastFixAt = null;
    session.distanceAnchorAt = null;
    await _saveActive();
    notifyListeners();
    if (session.usesGps) await _startGps();
  }

  Future<TrackedWorkoutResult?> finish() async {
    final session = current;
    if (session == null) return null;
    if (session.isRunning) await pause();
    session.endedAt = DateTime.now().toUtc();
    await _stopGps();
    session.lastLatitude = null;
    session.lastLongitude = null;
    session.lastAccuracy = null;
    session.lastFixAt = null;
    session.distanceAnchorAt = null;
    _pending.add(session);
    current = null;
    await _saveActive();
    await _savePending();
    notifyListeners();
    return _submit(session);
  }

  Future<void> retryPending() async {
    if (submitting) return;
    for (final session in List<TrackedWorkout>.from(_pending)) {
      try {
        await _submit(session);
      } catch (_) {
        break;
      }
    }
  }

  Future<TrackedWorkoutResult?> _submit(TrackedWorkout session) async {
    if (session.endedAt == null) return null;
    submitting = true;
    notifyListeners();
    try {
      final response = await ApiClient.instance.post(
        '/activity/tracked-sessions',
        data: session.toApiJson(),
        options: ApiClient.mutationOptions(session.id),
      );
      final result = TrackedWorkoutResult.fromJson(
          Map<String, dynamic>.from(response.data as Map));
      _pending.removeWhere((x) => x.id == session.id);
      await _savePending();
      error = null;
      return result;
    } catch (failure) {
      final reason = ApiFailure.from(failure,
          fallback: 'Could not sync this workout. Try again later.');
      error = failure is DioException && failure.response == null
          ? 'Workout saved on this phone. It will sync when online.'
          : 'Workout saved on this phone. Sync failed: ${reason.message}';
      return null;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Future<void> _startGps() async {
    if (kIsWeb) return;
    gpsAvailable = false;
    gpsMessage = 'Waiting for an accurate GPS signal…';
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        gpsMessage = 'Phone location is off. Turn it on to measure distance.';
        notifyListeners();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        gpsMessage = 'Allow location access to measure outdoor distance.';
        notifyListeners();
        return;
      }
      if (await Geolocator.getLocationAccuracy() ==
          LocationAccuracyStatus.reduced) {
        gpsMessage = 'Enable precise location to measure outdoor distance.';
        notifyListeners();
        return;
      }
      final LocationSettings settings;
      if (Platform.isAndroid) {
        settings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Life-Level workout in progress',
            notificationText: 'Measuring your outdoor workout distance',
            enableWakeLock: true,
          ),
        );
      } else {
        settings = apple.AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: apple.ActivityType.fitness,
          distanceFilter: 5,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        );
      }
      _positions =
          Geolocator.getPositionStream(locationSettings: settings).listen(
        _onPosition,
        onError: (_) {
          gpsAvailable = false;
          gpsMessage = 'GPS stopped. Check your phone location settings.';
          notifyListeners();
        },
      );
      notifyListeners();
    } catch (_) {
      gpsAvailable = false;
      gpsMessage = 'GPS could not start. Check your phone location settings.';
      notifyListeners();
    }
  }

  void _onPosition(Position fix) {
    final session = current;
    if (session == null || !session.recordPosition(fix)) return;
    gpsAvailable = true;
    gpsMessage = null;
    unawaited(_saveActive().catchError((_) {
      error = 'Could not save GPS progress on this phone.';
      notifyListeners();
    }));
    notifyListeners();
  }

  Future<void> _stopGps() async {
    await _positions?.cancel();
    _positions = null;
    gpsAvailable = false;
    gpsMessage = null;
  }

  Future<void> _saveActive() {
    final snapshot = current == null ? null : jsonEncode(current!.toJson());
    _activeWrite = _activeWrite.catchError((_) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (snapshot == null) {
        await prefs.remove(_scopedActiveKey);
      } else {
        await prefs.setString(_scopedActiveKey, snapshot);
      }
    });
    return _activeWrite;
  }

  Future<void> _savePending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scopedPendingKey,
        _pending.map((x) => jsonEncode(x.toJson())).toList());
  }

  @override
  void dispose() {
    unawaited(_stopGps());
    super.dispose();
  }
}
