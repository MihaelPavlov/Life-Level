import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';
import '../models/streak_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final streakServiceProvider = Provider<StreakService>((ref) => StreakService());

// ── Streak notifier ────────────────────────────────────────────────────────────
class StreakNotifier extends AsyncNotifier<StreakData> {
  @override
  Future<StreakData> build() =>
      ref.watch(streakServiceProvider).getStreak();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(streakServiceProvider).getStreak(),
    );
  }

  Future<UseShieldResult> useShield() async {
    final result = await ref.read(streakServiceProvider).useShield();
    if (result.success) await refresh();
    return result;
  }
}

final streakProvider =
    AsyncNotifierProvider<StreakNotifier, StreakData>(StreakNotifier.new);
