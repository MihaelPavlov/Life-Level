import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/integration_models.dart';
import '../services/health_sync_service.dart';
import '../services/strava_service.dart';
import '../services/garmin_service.dart';

final integrationSyncProvider =
    NotifierProvider<IntegrationSyncNotifier, IntegrationSyncState>(
  IntegrationSyncNotifier.new,
);

class IntegrationSyncNotifier extends Notifier<IntegrationSyncState> {
  final _service = HealthSyncService();
  final _strava = StravaService();
  final _garmin = GarminService();

  @override
  IntegrationSyncState build() {
    _loadInitialState();
    return const IntegrationSyncState(
      isHealthConnected: false,
      isSyncing: false,
    );
  }

  Future<void> _loadInitialState() async {
    final granted = await _service.isPermissionGranted();
    final lastSync = await _service.getLastSyncTime();

    // On error, preserve the last known connected state rather than resetting
    // to false — prevents a transient failure from wiping a valid session.
    StravaStatusDto stravaStatus;
    try {
      stravaStatus = await _strava.getStatus();
    } catch (_) {
      stravaStatus = StravaStatusDto(
        isConnected: state.isStravaConnected,
        athleteName: state.stravaAthleteName,
      );
    }

    GarminStatusDto garminStatus;
    try {
      garminStatus = await _garmin.getStatus();
    } catch (_) {
      garminStatus = GarminStatusDto(
        isConnected: state.isGarminConnected,
        displayName: state.garminDisplayName,
      );
    }

    state = state.copyWith(
      isHealthConnected: granted,
      lastSyncAt: lastSync,
      isStravaConnected: stravaStatus.isConnected,
      stravaAthleteName: stravaStatus.athleteName,
      isGarminConnected: garminStatus.isConnected,
      garminDisplayName: garminStatus.displayName,
    );
  }

  Future<void> refresh() async {
    await _loadInitialState();
  }

  Future<void> requestPermissions() async {
    final granted = await _service.requestPermissions();
    state = state.copyWith(isHealthConnected: granted);
    if (granted) await syncNow();
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, lastResult: null);
    final result = await _service.syncRecentWorkouts();
    final lastSync = await _service.getLastSyncTime();
    state = state.copyWith(
      isSyncing: false,
      lastSyncAt: lastSync,
      lastResult: result,
      isHealthConnected: true,
    );
  }

  /// Returns null on success, or an error message on failure.
  Future<String?> connectStrava(String code) async {
    try {
      final status = await _strava.connect(code);
      state = state.copyWith(
        isStravaConnected: status.isConnected,
        stravaAthleteName: status.athleteName,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> disconnectStrava() async {
    try {
      await _strava.disconnect();
      state = state.copyWith(
        isStravaConnected: false,
        clearStravaAthleteName: true,
      );
    } catch (_) {}
  }

  Future<void> connectGarmin(String code, String codeVerifier) async {
    try {
      final status = await _garmin.connect(code, codeVerifier);
      state = state.copyWith(
        isGarminConnected: status.isConnected,
        garminDisplayName: status.displayName,
      );
    } catch (_) {}
  }

  Future<void> disconnectGarmin() async {
    try {
      await _garmin.disconnect();
      state = state.copyWith(
        isGarminConnected: false,
        clearGarminDisplayName: true,
      );
    } catch (_) {}
  }
}
