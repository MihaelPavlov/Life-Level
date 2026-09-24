import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/streak/models/streak_models.dart';

void main() {
  test('parses a stackable daily streak reward', () {
    final streak = StreakData.fromJson({
      'current': 3,
      'longest': 5,
      'shieldsAvailable': 0,
      'shieldUsedToday': false,
      'lastActivityDate': '2026-09-24T00:00:00Z',
      'totalDaysActive': 7,
      'pendingRewardCoins': 60,
      'canClaimDailyReward': true,
      'nextRewardCoins': 40,
    });

    expect(streak.canClaimDailyReward, isTrue);
    expect(streak.pendingRewardCoins, 60);
    expect(streak.nextRewardCoins, 40);
  });
}
