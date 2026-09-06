import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/features/season/models/season_models.dart';
import 'package:life_level/features/season/widgets/season_reward_sheet.dart';

const _result = SeasonClaimResult(
  tier: 1,
  track: 'Founder',
  label: '+250 XP',
  xpAwarded: 250,
  leveledUp: false,
  newLevel: null,
  grantedItemName: null,
  grantedTitleKey: null,
);

void main() {
  testWidgets('reward pop-up has no Continue button and auto-dismisses',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.expand();
      })),
    ));

    showSeasonRewardSheet(ctx, _result);
    await tester.pump(); // start the route
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('+250 XP'), findsOneWidget);
    expect(find.text('FOUNDER · TIER 1 COLLECTED'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsNothing);
    expect(find.text('Continue'), findsNothing);

    // Auto-dismiss window elapses.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('+250 XP'), findsNothing);
  });

  testWidgets('claiming again replaces the pop-up instead of stacking',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.expand();
      })),
    ));

    showSeasonRewardSheet(ctx, _result);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    showSeasonRewardSheet(
        ctx,
        const SeasonClaimResult(
          tier: 2,
          track: 'Free',
          label: 'Streak Freeze ×1',
          xpAwarded: 0,
          leveledUp: false,
          newLevel: null,
          grantedItemName: null,
          grantedTitleKey: null,
        ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('+250 XP'), findsNothing);
    expect(find.text('Streak Freeze ×1'), findsWidgets);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
