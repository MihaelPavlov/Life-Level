import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/level_up_notifier.dart';
import '../../../core/session/invalidate_user_providers.dart';
import '../../integrations/models/integration_models.dart';
import '../../integrations/services/health_sync_service.dart';
import '../models/pending_models.dart';
import '../services/pending_workouts_service.dart';

final pendingWorkoutsServiceProvider =
    Provider<PendingWorkoutsService>((ref) => PendingWorkoutsService());

/// Reads Health Connect / Apple Health on the phone. Overridden in tests.
abstract class LocalWorkoutReader {
  Future<List<ExternalActivityDto>?> readForStaging();
  Future<void> markStaged();
}

class _HealthStoreReader implements LocalWorkoutReader {
  final _health = HealthSyncService();
  @override
  Future<List<ExternalActivityDto>?> readForStaging() =>
      _health.readForStaging();
  @override
  Future<void> markStaged() => _health.markStaged();
}

final localWorkoutReaderProvider =
    Provider<LocalWorkoutReader>((ref) => _HealthStoreReader());

/// Runs after workouts were imported: refresh everything XP, stats, quests,
/// the map and bosses touch, and let the shell check for a level-up.
final pendingImportRefreshProvider = Provider<void Function()>((ref) => () {
      invalidateProgressProviders(ref);
      LevelUpNotifier.checkPending();
    });

class PendingWorkoutsState {
  final PendingWorkoutList list;
  final DateTime? lastCheckedAt;
  final bool checking;
  final bool importing;

  const PendingWorkoutsState({
    this.list = PendingWorkoutList.empty,
    this.lastCheckedAt,
    this.checking = false,
    this.importing = false,
  });

  int get pendingCount => list.pendingCount;

  PendingWorkoutsState copyWith({
    PendingWorkoutList? list,
    DateTime? lastCheckedAt,
    bool? checking,
    bool? importing,
  }) =>
      PendingWorkoutsState(
        list: list ?? this.list,
        lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
        checking: checking ?? this.checking,
        importing: importing ?? this.importing,
      );
}

/// The pending-workout queue as the app sees it.
///
/// [check] is what a pull on Home does: read the phone's health store,
/// queue anything new on our server, then read the queue back. It never
/// calls Strava or Garmin; their workouts arrive through webhooks.
final pendingWorkoutsProvider =
    NotifierProvider<PendingWorkoutsNotifier, PendingWorkoutsState>(
  PendingWorkoutsNotifier.new,
);

class PendingWorkoutsNotifier extends Notifier<PendingWorkoutsState> {
  static const _lastCheckedKey = 'pending_last_checked_ms';

  @override
  PendingWorkoutsState build() {
    _restoreLastChecked();
    return const PendingWorkoutsState();
  }

  Future<void> _restoreLastChecked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_lastCheckedKey);
      if (ms != null && state.lastCheckedAt == null) {
        state = state.copyWith(
            lastCheckedAt: DateTime.fromMillisecondsSinceEpoch(ms));
      }
    } catch (_) {}
  }

  /// Reads the phone's health store, queues anything new, then returns the
  /// queue. Throws when the server can't be reached; nothing is lost then,
  /// because provider workouts already sit in the queue on the server.
  Future<PendingWorkoutList> check() async {
    state = state.copyWith(checking: true);
    try {
      final service = ref.read(pendingWorkoutsServiceProvider);
      final reader = ref.read(localWorkoutReaderProvider);
      List<ExternalActivityDto>? local;
      try {
        local = await reader.readForStaging();
      } catch (_) {
        local = null; // The health store failing must not block the queue.
      }
      final PendingWorkoutList list;
      if (local != null && local.isNotEmpty) {
        list = await service.stage(local);
        await reader.markStaged();
      } else {
        list = await service.list();
        if (local != null) await reader.markStaged();
      }
      final now = DateTime.now();
      state = state.copyWith(list: list, lastCheckedAt: now, checking: false);
      _saveLastChecked(now);
      return list;
    } catch (_) {
      state = state.copyWith(checking: false);
      rethrow;
    }
  }

  /// Background refresh (app resume, push notification): same as [check]
  /// but never throws.
  Future<void> checkQuietly() async {
    if (state.checking || state.importing) return;
    try {
      await check();
    } catch (_) {}
  }

  /// Imports the selected workouts and refreshes everything they touch.
  Future<ImportPendingResult> import(List<String> ids) async {
    state = state.copyWith(importing: true);
    try {
      final result = await ref.read(pendingWorkoutsServiceProvider).import(ids);
      final remaining =
          state.list.items.where((w) => !ids.contains(w.id)).toList();
      state = state.copyWith(
        list: PendingWorkoutList(
          items: remaining,
          pendingCount: result.remainingPending,
        ),
        importing: false,
        lastCheckedAt: DateTime.now(),
      );
      if (result.imported.isNotEmpty) ref.read(pendingImportRefreshProvider)();
      return result;
    } catch (_) {
      state = state.copyWith(importing: false);
      rethrow;
    }
  }

  Future<void> _saveLastChecked(DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckedKey, at.millisecondsSinceEpoch);
    } catch (_) {}
  }
}
