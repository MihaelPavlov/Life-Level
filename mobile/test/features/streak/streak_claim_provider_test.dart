import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/streak/models/streak_models.dart';
import 'package:life_level/features/streak/providers/streak_provider.dart';
import 'package:life_level/features/streak/services/streak_service.dart';

class _AlreadyClaimedService extends StreakService {
  int reads = 0;

  @override
  Future<StreakData> getStreak() async {
    reads++;
    return StreakData(
      current: 1,
      longest: 1,
      shieldsAvailable: 0,
      shieldUsedToday: false,
      lastActivityDate: null,
      totalDaysActive: 1,
      pendingRewardCoins: reads == 1 ? 10 : 0,
      canClaimDailyReward: reads == 1,
      nextRewardCoins: 20,
    );
  }

  @override
  Future<ClaimStreakRewardResult> claimReward() async =>
      throw const StreakException('No streak reward is ready to claim.');
}

void main() {
  test('a rejected claim refreshes stale claimable state', () async {
    final service = _AlreadyClaimedService();
    final container = ProviderContainer(overrides: [
      streakServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);

    expect((await container.read(streakProvider.future)).canClaimDailyReward,
        isTrue);
    await expectLater(
      container.read(streakProvider.notifier).claimReward(),
      throwsA(isA<StreakException>()),
    );
    expect(container.read(streakProvider).valueOrNull?.canClaimDailyReward,
        isFalse);
  });
}
