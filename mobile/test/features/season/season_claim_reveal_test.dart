import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/features/season/models/season_models.dart';
import 'package:life_level/features/season/widgets/season_claim_reveal.dart';

SeasonRewardView _view(String type, String label, int amount,
        {String icon = 'reward_xp_sparkle', String? rarity}) =>
    SeasonRewardView(
      type: type,
      label: label,
      iconKey: icon,
      amount: amount,
      rarity: rarity,
      state: SeasonRewardState.ready,
    );

/// Season 1 tiers 1–5 from the real catalog.
final _before = SeasonTrack(
  hasActiveSeason: true,
  season: SeasonHeader(
    id: 's1',
    number: 1,
    name: 'Trail of Embers',
    theme: 'ember',
    endsAt: DateTime(2026, 12, 1),
    daysLeft: 48,
  ),
  xpPerTier: 600,
  tierCount: 25,
  milestoneTier: 25,
  seasonXp: 3000,
  currentTier: 5,
  xpIntoTier: 0,
  xpToNextTier: 600,
  hasFounderPass: true,
  nextReward: null,
  tiers: [
    SeasonTier(
        tier: 1,
        isMilestone: false,
        free: _view('SeasonXp', '+150 Season XP', 150),
        founder: _view('Xp', '+250 XP', 250)),
    SeasonTier(
        tier: 2,
        isMilestone: false,
        free: _view('Xp', '+250 XP', 250),
        founder: _view('StreakShield', 'Streak Freeze ×1', 1,
            icon: 'reward_streak_shield')),
    SeasonTier(
        tier: 3,
        isMilestone: false,
        free: _view('StreakShield', 'Streak Freeze ×1', 1,
            icon: 'reward_streak_shield'),
        founder: _view('Xp', '+400 XP', 400)),
    SeasonTier(
        tier: 4,
        isMilestone: false,
        free: _view('SeasonXp', '+200 Season XP', 200),
        founder: _view('Item', 'Iron Headband', 0,
            icon: 'reward_treasure_chest', rarity: 'common')),
    SeasonTier(
        tier: 5,
        isMilestone: false,
        free: _view('Xp', '+300 XP', 300),
        founder: _view('Title', '"The Marathoner" title', 0,
            icon: 'title_marathoner', rarity: 'rare')),
  ],
);

SeasonClaimResult _claim(int tier, String track,
        {int xp = 0, bool up = false, String? item, String? title}) =>
    SeasonClaimResult(
      tier: tier,
      track: track,
      label: 'Reward',
      xpAwarded: xp,
      leveledUp: up,
      newLevel: up ? 7 : null,
      grantedItemName: item,
      grantedTitleKey: title,
    );

Future<BuildContext> _host(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Builder(builder: (c) {
      ctx = c;
      return const SizedBox.expand();
    })),
  ));
  return ctx;
}

void main() {
  testWidgets('one reward shows the centred reveal and closes on Continue',
      (tester) async {
    final ctx = await _host(tester);
    var closed = false;
    showSeasonClaimReveal(ctx,
            results: [_claim(4, 'Founder', item: 'Iron Headband')],
            before: _before)
        .then((_) => closed = true);
    await tester.pumpAndSettle();

    expect(find.text('FOUNDER TRACK · TIER 4'), findsOneWidget);
    expect(find.text('Reward collected'), findsOneWidget);
    expect(find.text('Iron Headband'), findsOneWidget);
    expect(find.text('COMMON'), findsOneWidget);
    expect(find.text('Iron Headband added to your bag'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(find.text('Reward collected'), findsNothing);
  });

  testWidgets('two to four rewards show totals and a card grid',
      (tester) async {
    final ctx = await _host(tester);
    showSeasonClaimReveal(ctx, results: [
      _claim(1, 'Free'),
      _claim(2, 'Free', xp: 250),
      _claim(3, 'Free'),
      _claim(4, 'Free'),
    ], before: _before);
    await tester.pumpAndSettle();

    expect(find.text('4 rewards collected'), findsOneWidget);
    expect(find.text('TRAIL OF EMBERS · TIERS 1 – 4'), findsOneWidget);
    expect(find.text('Free track'), findsOneWidget);
    expect(find.text('+250'), findsOneWidget); // XP total
    expect(find.text('+350'), findsOneWidget); // Season XP total
    expect(find.text('+150 Season XP'), findsOneWidget);
    expect(find.text('Streak Freeze ×1'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('five or more rewards list by track with title and level up',
      (tester) async {
    final ctx = await _host(tester);
    showSeasonClaimReveal(ctx, results: [
      _claim(1, 'Founder', xp: 250),
      _claim(2, 'Founder'),
      _claim(3, 'Founder', xp: 400, up: true),
      _claim(4, 'Founder', item: 'Iron Headband'),
      _claim(5, 'Founder', title: 'the-marathoner'),
      _claim(5, 'Free', xp: 300),
    ], before: _before);
    await tester.pumpAndSettle();

    expect(find.text('6 rewards collected'), findsOneWidget);
    expect(find.text('Free + Founder tracks'), findsOneWidget);
    expect(find.text('+950 XP'), findsOneWidget);
    expect(find.text('LEVEL UP'), findsOneWidget);
    expect(find.text('NEW TITLE · RARE'), findsOneWidget);
    expect(find.text('"The Marathoner" title'), findsOneWidget);
    expect(find.text('FREE TRACK'), findsOneWidget);
    expect(find.text('FOUNDER TRACK'), findsOneWidget);
    expect(find.text('Continue to Level 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
