import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';
import '../models/streak_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final streakServiceProvider = Provider<StreakService>((ref) => StreakService());

// ── Streak notifier ────────────────────────────────────────────────────────────
class StreakNotifier extends AsyncNotifier<StreakData> {
  @override
  Future<StreakData> build() => ref.watch(streakServiceProvider).getStreak();

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

  Future<ClaimStreakRewardResult> claimReward() async {
    try {
      return await ref.read(streakServiceProvider).claimReward();
    } finally {
      // A second device may have claimed first. Refresh even when the API
      // rejects this request so its stale Claim button disappears.
      await refresh();
    }
  }
}

final streakProvider =
    AsyncNotifierProvider<StreakNotifier, StreakData>(StreakNotifier.new);
