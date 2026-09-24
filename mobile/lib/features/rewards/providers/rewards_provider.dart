import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rewards_service.dart';
import '../models/rewards_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final rewardsServiceProvider =
    Provider<RewardsService>((ref) => RewardsService());

class RewardCenterNotifier extends AsyncNotifier<RewardCenterData> {
  @override
  Future<RewardCenterData> build() =>
      ref.watch(rewardsServiceProvider).getRewardCenter();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(rewardsServiceProvider).getRewardCenter(),
    );
  }

  Future<void> claimMilestone(String period, int threshold) async {
    await ref.read(rewardsServiceProvider).claimMilestone(period, threshold);
    await refresh();
  }

  Future<TaskRewardsClaimResult> claimAvailableTaskRewards(
      String period) async {
    final previous = state.valueOrNull;
    final result = await ref
        .read(rewardsServiceProvider)
        .claimAvailableTaskRewards(period);
    if (previous == null) {
      await refresh();
    } else {
      final updatedWallet = RewardWallet(
        coins: previous.wallet.coins + result.coins,
        crystals: previous.wallet.crystals + result.crystals,
      );
      state = AsyncData(RewardCenterData(
        wallet: updatedWallet,
        daily: result.period.toLowerCase() == 'daily'
            ? result.updatedPeriod
            : previous.daily,
        weekly: result.period.toLowerCase() == 'weekly'
            ? result.updatedPeriod
            : previous.weekly,
      ));
    }
    return result;
  }

  Future<List<MilestoneClaimResult>> claimAvailableMilestones(
      String period) async {
    final results =
        await ref.read(rewardsServiceProvider).claimAvailableMilestones(period);
    await refresh();
    return results;
  }
}

final rewardCenterProvider =
    AsyncNotifierProvider<RewardCenterNotifier, RewardCenterData>(
  RewardCenterNotifier.new,
);
