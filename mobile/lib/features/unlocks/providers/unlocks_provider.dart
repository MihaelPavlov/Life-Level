import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/unlock_models.dart';
import '../services/unlocks_service.dart';

final unlocksServiceProvider =
    Provider<UnlocksService>((_) => UnlocksService());

class UnlocksNotifier extends AsyncNotifier<UnlocksSnapshot> {
  @override
  Future<UnlocksSnapshot> build() =>
      ref.read(unlocksServiceProvider).getUnlocks();

  /// Re-checks the chain (after a workout, a level-up, a sync…). Keeps the
  /// current list visible while it loads.
  Future<void> refresh() async {
    final next =
        await AsyncValue.guard(ref.read(unlocksServiceProvider).getUnlocks);
    if (next.hasValue || !state.hasValue) state = next;
  }

  Future<void> markSeen(String key) async {
    _patch(key, (u) => u.copyWith(seen: true));
    try {
      await ref.read(unlocksServiceProvider).markSeen(key);
    } catch (_) {
      // Seen is best-effort: at worst the ceremony shows again next launch.
    }
  }

  /// Returns the XP awarded for finishing the tour.
  Future<int> markToured(String key) async {
    _patch(key, (u) => u.copyWith(seen: true, toured: true));
    try {
      return await ref.read(unlocksServiceProvider).markToured(key);
    } catch (_) {
      return 0;
    }
  }

  void _patch(String key, UnlockState Function(UnlockState) f) {
    final s = state.valueOrNull;
    if (s != null) state = AsyncData(s.update(key, f));
  }
}

final unlocksProvider = AsyncNotifierProvider<UnlocksNotifier, UnlocksSnapshot>(
    UnlocksNotifier.new);

/// The chain, or "everything open" while it loads or if it fails.
final unlocksSnapshotProvider = Provider<UnlocksSnapshot>(
    (ref) => ref.watch(unlocksProvider).valueOrNull ?? UnlocksSnapshot.open);

final isUnlockedProvider = Provider.family<bool, String>(
    (ref, key) => ref.watch(unlocksSnapshotProvider).isUnlocked(key));

/// Unlocked but not toured yet: the NEW pill.
final isFreshUnlockProvider = Provider.family<bool, String>(
    (ref, key) => ref.watch(unlocksSnapshotProvider).isFresh(key));
