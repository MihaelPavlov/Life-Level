import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/rewards/models/rewards_models.dart';
import 'package:life_level/features/rewards/providers/rewards_provider.dart';
import 'package:life_level/features/rewards/rewards_screen.dart';

void main() {
  testWidgets('hides wallet balances and shows Daily and Weekly task tracks',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardCenterProvider.overrideWith(
            () => _FakeRewardCenterNotifier(_rewardCenter()),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: RewardsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('425'), findsNothing);
    expect(find.text('7'), findsNothing);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('1 TASKS'), findsOneWidget);
    expect(find.text('Complete ten active minutes.'), findsOneWidget);
    expect(find.text('Move for ten minutes'), findsNothing);
    expect(find.text('CUMULATIVE'), findsNothing);
    expect(find.text('+20'), findsOneWidget);
    expect(find.textContaining('Task rewards are received automatically'),
        findsNothing);
    expect(find.text('TASK'), findsNothing);
    expect(find.text('POINTS'), findsNothing);
  });

  testWidgets('fits a compact phone viewport without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardCenterProvider.overrideWith(
            () => _FakeRewardCenterNotifier(_rewardCenter()),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: RewardsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('claim button claims all ready tasks and refreshes task points',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final notifier = _FakeRewardCenterNotifier(
      _rewardCenter(dailyEarned: 0, dailyCompleted: true),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [rewardCenterProvider.overrideWith(() => notifier)],
        child: const MaterialApp(home: Scaffold(body: RewardsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    final taskClaimButton = find.widgetWithText(FilledButton, 'CLAIM');
    expect(taskClaimButton, findsOneWidget);
    await tester.tap(taskClaimButton);
    await tester.pumpAndSettle();

    expect(notifier.taskClaims, 1);
    expect(find.widgetWithText(FilledButton, 'CLAIM'), findsNothing);
    expect(notifier.current.daily.pointsEarned, 20);
    expect(notifier.current.daily.tasks.single.rewardClaimed, isTrue);
    await tester.pump(const Duration(seconds: 4));
  });
}

class _FakeRewardCenterNotifier extends RewardCenterNotifier {
  RewardCenterData current;
  int taskClaims = 0;

  _FakeRewardCenterNotifier(this.current);

  @override
  Future<RewardCenterData> build() async => current;

  @override
  Future<TaskRewardsClaimResult> claimAvailableTaskRewards(
      String period) async {
    taskClaims++;
    current = _rewardCenter(
      dailyEarned: 20,
      dailyCompleted: true,
      dailyRewardClaimed: true,
    );
    state = AsyncData(current);
    return TaskRewardsClaimResult(
      period: 'Daily',
      tasksClaimed: 1,
      coins: 35,
      crystals: 0,
      updatedPeriod: current.daily,
    );
  }
}

RewardCenterData _rewardCenter({
  int dailyEarned = 20,
  bool dailyCompleted = false,
  bool dailyRewardClaimed = false,
}) =>
    RewardCenterData.fromJson({
      'wallet': {'coins': 425, 'crystals': 7},
      'daily': _period(
        'Daily',
        dailyEarned,
        100,
        completed: dailyCompleted,
        rewardClaimed: dailyRewardClaimed,
      ),
      'weekly': _period('Weekly', 40, 200),
    });

Map<String, dynamic> _period(
  String period,
  int earned,
  int maximum, {
  bool completed = false,
  bool rewardClaimed = false,
}) =>
    {
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
      'tasks': [
        {
          'id': '00000000-0000-0000-0000-000000000001',
          'questId': '00000000-0000-0000-0000-000000000002',
          'title': 'Move for ten minutes',
          'description': 'Complete ten active minutes.',
          'type': period,
          'category': 'Duration',
          'progressMode': 'Cumulative',
          'difficultyTier': 'Easy',
          'requiredActivity': null,
          'targetValue': 10,
          'currentValue': completed ? 10 : 5,
          'targetUnit': 'min',
          'rewardXp': 0,
          'rewardCoins': period == 'Daily' ? 35 : 30,
          'rewardCrystals': 0,
          'rewardPoints': 20,
          'isCompleted': completed,
          'rewardClaimed': rewardClaimed,
          'expiresAt': '2026-09-24T00:00:00Z',
          'completedAt': null,
        },
      ],
    };
