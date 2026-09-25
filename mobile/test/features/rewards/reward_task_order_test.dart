import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/quests/models/quest_models.dart';
import 'package:life_level/features/rewards/rewards_screen.dart';

void main() {
  test('ready tasks sort above active tasks and claimed tasks', () {
    final ordered = orderRewardTasksForDisplay([
      _task('claimed', completed: true, claimed: true),
      _task('active'),
      _task('ready', completed: true),
      _task('active-2'),
      _task('ready-2', completed: true),
    ]);

    expect(
      ordered.map((task) => task.title),
      ['ready', 'ready-2', 'active', 'active-2', 'claimed'],
    );
  });
}

UserQuestProgress _task(
  String title, {
  bool completed = false,
  bool claimed = false,
}) =>
    UserQuestProgress.fromJson({
      'id': title,
      'questId': 'quest-$title',
      'title': title,
      'description': title,
      'type': 'Daily',
      'category': 'Duration',
      'progressMode': 'Cumulative',
      'difficultyTier': 'Easy',
      'requiredActivity': null,
      'targetValue': 10,
      'currentValue': completed ? 10 : 5,
      'targetUnit': 'min',
      'rewardXp': 0,
      'rewardCoins': 35,
      'rewardCrystals': 0,
      'rewardPoints': 20,
      'isCompleted': completed,
      'rewardClaimed': claimed,
      'expiresAt': '2026-09-26T00:00:00Z',
      'completedAt': completed ? '2026-09-25T10:00:00Z' : null,
    });
