import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/constants/app_icons.dart';
import 'package:life_level/core/widgets/app_icon_image.dart';
import 'package:life_level/features/streak/models/streak_models.dart';
import 'package:life_level/features/streak/providers/streak_provider.dart';
import 'package:life_level/features/streak/widgets/streak_detail_sheet.dart';

class _FixtureStreak extends StreakNotifier {
  @override
  Future<StreakData> build() async => const StreakData(
        current: 1,
        longest: 1,
        shieldsAvailable: 0,
        shieldUsedToday: false,
        lastActivityDate: null,
        totalDaysActive: 1,
        pendingRewardCoins: 10,
        canClaimDailyReward: true,
        nextRewardCoins: 20,
      );
}

void main() {
  testWidgets('streak sheet uses original fire, coin, and shield assets',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [streakProvider.overrideWith(_FixtureStreak.new)],
      child: const MaterialApp(
        home: Scaffold(body: StreakDetailSheet()),
      ),
    ));
    await tester.pump();

    for (final asset in [
      AppIcons.rewardStreakFire,
      AppIcons.homeCoinIcon,
      AppIcons.rewardStreakShield,
    ]) {
      expect(
          find.byWidgetPredicate(
              (widget) => widget is AppIconImage && widget.asset == asset),
          findsWidgets);
    }
    expect(find.text('🪙'), findsNothing);
    expect(find.text('🛡️'), findsNothing);
  });
}
