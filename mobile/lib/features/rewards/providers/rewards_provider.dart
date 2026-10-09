import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/optimistic_mutation.dart';
import '../../../core/services/client_experience_service.dart';
import '../services/rewards_service.dart';
import '../models/rewards_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final rewardsServiceProvider =
    Provider<RewardsService>((ref) => RewardsService());

class RewardCenterNotifier extends AsyncNotifier<RewardCenterData> {
  final _mutation = OptimisticMutationController<RewardCenterData>();

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
    final current = state.requireValue;
    if (!ClientExperienceService.instance.enabled('rewards')) {
      final result = await ref
          .read(rewardsServiceProvider)
          .claimMilestone(period, threshold);
      state =
          AsyncData(_withPeriod(current, result.period, result.updatedPeriod));
      return;
    }
    await _mutation.run(
      current: current,
      optimistic: (value) =>
          _optimisticMilestones(value, period, threshold: threshold),
      request: () =>
          ref.read(rewardsServiceProvider).claimMilestone(period, threshold),
      reconcile: (predicted, result) =>
          _withPeriod(predicted, result.period, result.updatedPeriod),
      publish: (value) => state = AsyncData(value),
      feature: 'rewards',
      action: 'claim_milestone',
    );
  }

  Future<TaskRewardsClaimResult> claimAvailableTaskRewards(
      String period) async {
    final current = state.requireValue;
    if (!ClientExperienceService.instance.enabled('rewards')) {
      final result = await ref
          .read(rewardsServiceProvider)
          .claimAvailableTaskRewards(period);
      state =
          AsyncData(_withPeriod(current, result.period, result.updatedPeriod));
      return result;
    }
    return _mutation.run(
      current: current,
      optimistic: (value) => _optimisticTasks(value, period),
      request: () =>
          ref.read(rewardsServiceProvider).claimAvailableTaskRewards(period),
      reconcile: (predicted, result) =>
          _withPeriod(predicted, result.period, result.updatedPeriod),
      publish: (value) => state = AsyncData(value),
      feature: 'rewards',
      action: 'claim_tasks',
    );
  }

  Future<List<MilestoneClaimResult>> claimAvailableMilestones(
      String period) async {
    final current = state.requireValue;
    if (!ClientExperienceService.instance.enabled('rewards')) {
      final results = await ref
          .read(rewardsServiceProvider)
          .claimAvailableMilestones(period);
      if (results.isNotEmpty) {
        final last = results.last;
        state =
            AsyncData(_withPeriod(current, last.period, last.updatedPeriod));
      }
      return results;
    }
    return _mutation.run(
      current: current,
      optimistic: (value) => _optimisticMilestones(value, period),
      request: () =>
          ref.read(rewardsServiceProvider).claimAvailableMilestones(period),
      reconcile: (predicted, results) {
        final last = results.last;
        return _withPeriod(predicted, last.period, last.updatedPeriod);
      },
      publish: (value) => state = AsyncData(value),
      feature: 'rewards',
      action: 'claim_milestones',
    );
  }

  RewardCenterData _optimisticTasks(RewardCenterData data, String period) {
    final source = period.toLowerCase() == 'daily' ? data.daily : data.weekly;
    final claimable =
        source.tasks.where((task) => task.isCompleted && !task.rewardClaimed);
    final coins = claimable.fold<int>(0, (n, task) => n + task.rewardCoins);
    final gems = claimable.fold<int>(0, (n, task) => n + task.rewardCrystals);
    final updated = TaskRewardPeriod(
      period: source.period,
      periodStartUtc: source.periodStartUtc,
      resetAtUtc: source.resetAtUtc,
      pointsEarned: source.pointsEarned,
      pointsMaximum: source.pointsMaximum,
      milestones: source.milestones,
      tasks: [
        for (final task in source.tasks)
          task.isCompleted && !task.rewardClaimed
              ? task.copyWith(rewardClaimed: true)
              : task,
      ],
    );
    return _withPeriod(
      RewardCenterData(
        wallet: RewardWallet(
          coins: data.wallet.coins + coins,
          gems: data.wallet.gems + gems,
        ),
        daily: data.daily,
        weekly: data.weekly,
      ),
      period,
      updated,
    );
  }

  RewardCenterData _optimisticMilestones(RewardCenterData data, String period,
      {int? threshold}) {
    final source = period.toLowerCase() == 'daily' ? data.daily : data.weekly;
    final claimable = source.milestones.where((m) =>
        m.isUnlocked &&
        !m.isClaimed &&
        (threshold == null || m.threshold == threshold));
    final coins = claimable.fold<int>(0, (n, m) => n + m.reward.coins);
    final gems = claimable.fold<int>(0, (n, m) => n + m.reward.crystals);
    final updated = TaskRewardPeriod(
      period: source.period,
      periodStartUtc: source.periodStartUtc,
      resetAtUtc: source.resetAtUtc,
      pointsEarned: source.pointsEarned,
      pointsMaximum: source.pointsMaximum,
      milestones: [
        for (final milestone in source.milestones)
          milestone.isUnlocked &&
                  !milestone.isClaimed &&
                  (threshold == null || milestone.threshold == threshold)
              ? milestone.copyWith(isClaimed: true)
              : milestone,
      ],
      tasks: source.tasks,
    );
    return _withPeriod(
      RewardCenterData(
        wallet: RewardWallet(
          coins: data.wallet.coins + coins,
          gems: data.wallet.gems + gems,
        ),
        daily: data.daily,
        weekly: data.weekly,
      ),
      period,
      updated,
    );
  }

  RewardCenterData _withPeriod(
          RewardCenterData data, String period, TaskRewardPeriod updated) =>
      RewardCenterData(
        wallet: data.wallet,
        daily: period.toLowerCase() == 'daily' ? updated : data.daily,
        weekly: period.toLowerCase() == 'weekly' ? updated : data.weekly,
      );
}

final rewardCenterProvider =
    AsyncNotifierProvider<RewardCenterNotifier, RewardCenterData>(
  RewardCenterNotifier.new,
);
