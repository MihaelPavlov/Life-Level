import '../../quests/models/quest_models.dart';
import 'login_reward_models.dart';

class RewardWallet {
  final int coins;
  final int crystals;
  const RewardWallet({required this.coins, required this.crystals});
  factory RewardWallet.fromJson(Map<String, dynamic> j) => RewardWallet(
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        crystals: (j['crystals'] as num?)?.toInt() ?? 0,
      );
}

class MilestoneReward {
  final int coins;
  final int crystals;
  final int xp;
  final int shields;
  const MilestoneReward(
      {required this.coins,
      required this.crystals,
      required this.xp,
      required this.shields});
  factory MilestoneReward.fromJson(Map<String, dynamic> j) => MilestoneReward(
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        crystals: (j['crystals'] as num?)?.toInt() ?? 0,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        shields: (j['shields'] as num?)?.toInt() ?? 0,
      );
}

class RewardMilestone {
  final int threshold;
  final MilestoneReward reward;
  final bool isUnlocked;
  final bool isClaimed;
  const RewardMilestone(
      {required this.threshold,
      required this.reward,
      required this.isUnlocked,
      required this.isClaimed});
  factory RewardMilestone.fromJson(Map<String, dynamic> j) => RewardMilestone(
        threshold: (j['threshold'] as num).toInt(),
        reward: MilestoneReward.fromJson(j['reward'] as Map<String, dynamic>),
        isUnlocked: j['isUnlocked'] as bool? ?? false,
        isClaimed: j['isClaimed'] as bool? ?? false,
      );
}

class TaskRewardPeriod {
  final String period;
  final DateTime periodStartUtc;
  final DateTime resetAtUtc;
  final int pointsEarned;
  final int pointsMaximum;
  final List<RewardMilestone> milestones;
  final List<UserQuestProgress> tasks;
  const TaskRewardPeriod(
      {required this.period,
      required this.periodStartUtc,
      required this.resetAtUtc,
      required this.pointsEarned,
      required this.pointsMaximum,
      required this.milestones,
      required this.tasks});
  factory TaskRewardPeriod.fromJson(Map<String, dynamic> j) => TaskRewardPeriod(
        period: j['period'] as String,
        periodStartUtc: DateTime.parse(j['periodStartUtc'] as String),
        resetAtUtc: DateTime.parse(j['resetAtUtc'] as String),
        pointsEarned: (j['pointsEarned'] as num).toInt(),
        pointsMaximum: (j['pointsMaximum'] as num).toInt(),
        milestones: (j['milestones'] as List<dynamic>)
            .map((e) => RewardMilestone.fromJson(e as Map<String, dynamic>))
            .toList(),
        tasks: (j['tasks'] as List<dynamic>)
            .map((e) => UserQuestProgress.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One milestone claimed as part of a claim-available sweep — mirrors the
/// backend's `TaskMilestoneClaimResult`. Only `threshold`/`reward` are
/// parsed; the caller re-fetches the reward center afterward for the
/// authoritative period state, same as the single-milestone claim already did.
class MilestoneClaimResult {
  final int threshold;
  final MilestoneReward reward;
  const MilestoneClaimResult({required this.threshold, required this.reward});
  factory MilestoneClaimResult.fromJson(Map<String, dynamic> j) =>
      MilestoneClaimResult(
        threshold: (j['threshold'] as num).toInt(),
        reward: MilestoneReward.fromJson(j['reward'] as Map<String, dynamic>),
      );
}

class RewardCenterData {
  final RewardWallet wallet;
  final LoginRewardStatus login;
  final TaskRewardPeriod daily;
  final TaskRewardPeriod weekly;
  const RewardCenterData(
      {required this.wallet,
      required this.login,
      required this.daily,
      required this.weekly});
  factory RewardCenterData.fromJson(Map<String, dynamic> j) => RewardCenterData(
        wallet: RewardWallet.fromJson(j['wallet'] as Map<String, dynamic>),
        login: LoginRewardStatus.fromJson(j['login'] as Map<String, dynamic>),
        daily: TaskRewardPeriod.fromJson(j['daily'] as Map<String, dynamic>),
        weekly: TaskRewardPeriod.fromJson(j['weekly'] as Map<String, dynamic>),
      );
}
