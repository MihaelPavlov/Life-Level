import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/rewards/models/rewards_models.dart';

void main() {
  test('parses task-only reward center payload with wallet balances', () {
    final data = RewardCenterData.fromJson({
      'wallet': {'coins': 425, 'crystals': 7},
      'daily': _period('Daily', 40, 100),
      'weekly': _period('Weekly', 80, 200),
    });

    expect(data.wallet.coins, 425);
    expect(data.wallet.crystals, 7);
    expect(data.daily.period, 'Daily');
    expect(data.daily.pointsEarned, 40);
    expect(data.daily.milestones.single.isUnlocked, isTrue);
    expect(data.weekly.period, 'Weekly');
    expect(data.weekly.pointsMaximum, 200);
    expect(data.hasClaimableReward, isTrue);
  });

  test('completed unclaimed task is actionable without a milestone', () {
    final daily = TaskRewardPeriod.fromJson({
      ..._period('Daily', 0, 100),
      'milestones': <Map<String, dynamic>>[],
      'tasks': [_task(isCompleted: true, rewardClaimed: false)],
    });

    expect(daily.hasClaimableTask, isTrue);
    expect(daily.hasClaimableMilestone, isFalse);
    expect(daily.hasClaimableReward, isTrue);
  });

  test('claimed task is no longer actionable', () {
    final daily = TaskRewardPeriod.fromJson({
      ..._period('Daily', 20, 100),
      'milestones': <Map<String, dynamic>>[],
      'tasks': [_task(isCompleted: true, rewardClaimed: true)],
    });

    expect(daily.hasClaimableReward, isFalse);
  });
}

Map<String, dynamic> _task({
  required bool isCompleted,
  required bool rewardClaimed,
}) =>
    {
      'id': 'progress-1',
      'questId': 'quest-1',
      'title': 'Walk for 30 minutes',
      'description': 'Walk for 30 minutes',
      'category': 'duration',
      'targetValue': 30,
      'currentValue': isCompleted ? 30 : 0,
      'targetUnit': 'minutes',
      'rewardXp': 0,
      'rewardCoins': 35,
      'rewardCrystals': 0,
      'rewardPoints': 20,
      'isCompleted': isCompleted,
      'rewardClaimed': rewardClaimed,
      'expiresAt': '2026-09-25T00:00:00Z',
      'completedAt': isCompleted ? '2026-09-24T08:00:00Z' : null,
    };

Map<String, dynamic> _period(String period, int earned, int maximum) => {
      'period': period,
      'periodStartUtc': '2026-09-23T00:00:00Z',
      'resetAtUtc': '2026-09-24T00:00:00Z',
      'pointsEarned': earned,
      'pointsMaximum': maximum,
      'milestones': [
        {
          'threshold': earned,
          'reward': {'coins': 25, 'crystals': 0, 'xp': 0, 'shields': 0},
          'isUnlocked': true,
          'isClaimed': false,
        },
      ],
      'tasks': <Map<String, dynamic>>[],
    };
