import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';
import '../models/streak_models.dart';
import '../../../core/state/optimistic_mutation.dart';
import '../../../core/services/client_experience_service.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final streakServiceProvider = Provider<StreakService>((ref) => StreakService());

// ── Streak notifier ────────────────────────────────────────────────────────────
class StreakNotifier extends AsyncNotifier<StreakData> {
  final _mutation = OptimisticMutationController<StreakData>();
  @override
  Future<StreakData> build() => ref.watch(streakServiceProvider).getStreak();

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    final next = await AsyncValue.guard(
      () => ref.read(streakServiceProvider).getStreak(),
    );
    if (next.hasValue || previous == null) state = next;
  }

  Future<UseShieldResult> useShield() async {
    final current = state.requireValue;
    if (!ClientExperienceService.instance.enabled('streakSeason')) {
      final result = await ref.read(streakServiceProvider).useShield();
      if (result.success) {
        state = AsyncData(current.copyWith(
          shieldsAvailable: result.shieldsRemaining,
          shieldUsedToday: true,
        ));
      }
      return result;
    }
    return _mutation.run(
      current: current,
      optimistic: (value) => value.copyWith(
        shieldsAvailable: value.shieldsAvailable - 1,
        shieldUsedToday: true,
      ),
      request: () => ref.read(streakServiceProvider).useShield(),
      reconcile: (predicted, result) => result.success
          ? predicted.copyWith(shieldsAvailable: result.shieldsRemaining)
          : current,
      publish: (value) => state = AsyncData(value),
      feature: 'streakSeason',
      action: 'use_shield',
    );
  }

  Future<ClaimStreakRewardResult> claimReward() async {
    final current = state.requireValue;
    if (!ClientExperienceService.instance.enabled('streakSeason')) {
      final result = await ref.read(streakServiceProvider).claimReward();
      state = AsyncData(current.copyWith(
        pendingRewardCoins: 0,
        canClaimDailyReward: false,
      ));
      return result;
    }
    try {
      return await _mutation.run(
        current: current,
        optimistic: (value) => value.copyWith(
          pendingRewardCoins: 0,
          canClaimDailyReward: false,
        ),
        request: () => ref.read(streakServiceProvider).claimReward(),
        reconcile: (predicted, _) => predicted,
        publish: (value) => state = AsyncData(value),
        feature: 'streakSeason',
        action: 'claim_streak_reward',
      );
    } catch (_) {
      // Reconcile a possible second-device claim before exposing the error.
      await refresh();
      rethrow;
    }
  }
}

final streakProvider =
    AsyncNotifierProvider<StreakNotifier, StreakData>(StreakNotifier.new);
