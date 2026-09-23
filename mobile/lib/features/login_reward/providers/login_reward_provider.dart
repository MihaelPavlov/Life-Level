import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/login_reward_service.dart';
import '../models/login_reward_models.dart';
import '../models/reward_center_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final loginRewardServiceProvider =
    Provider<LoginRewardService>((ref) => LoginRewardService());

// ── Status provider ────────────────────────────────────────────────────────────
final loginRewardStatusProvider = FutureProvider.autoDispose<LoginRewardStatus>(
  (ref) => ref.read(loginRewardServiceProvider).getStatus(),
);

class RewardCenterNotifier extends AsyncNotifier<RewardCenterData> {
  @override
  Future<RewardCenterData> build() =>
      ref.watch(loginRewardServiceProvider).getRewardCenter();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loginRewardServiceProvider).getRewardCenter(),
    );
  }

  Future<void> claimMilestone(String period, int threshold) async {
    await ref
        .read(loginRewardServiceProvider)
        .claimMilestone(period, threshold);
    await refresh();
  }

  Future<List<MilestoneClaimResult>> claimAvailableMilestones(
      String period) async {
    final results = await ref
        .read(loginRewardServiceProvider)
        .claimAvailableMilestones(period);
    await refresh();
    return results;
  }
}

final rewardCenterProvider =
    AsyncNotifierProvider<RewardCenterNotifier, RewardCenterData>(
  RewardCenterNotifier.new,
);
