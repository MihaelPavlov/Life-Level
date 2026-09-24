import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/features/season/models/season_models.dart';
import 'package:life_level/features/season/providers/season_provider.dart';
import 'package:life_level/features/season/season_track_screen.dart';
import 'package:life_level/features/season/widgets/season_tier_row.dart';

class _FakeSeasonNotifier extends SeasonNotifier {
  _FakeSeasonNotifier(this._data);
  final SeasonTrack _data;

  @override
  Future<SeasonTrack> build() async => _data;
}

SeasonRewardView _rv(String state,
        {String type = 'Xp', String label = '+250 XP'}) =>
    SeasonRewardView(
      type: type,
      label: label,
      iconKey: 'reward_xp_sparkle',
      amount: 250,
      rarity: null,
      state: _stateOf(state),
    );

SeasonRewardState _stateOf(String s) => {
      'received': SeasonRewardState.received,
      'locked': SeasonRewardState.locked,
      'pending': SeasonRewardState.pending,
      'ready': SeasonRewardState.ready,
    }[s]!;

SeasonTrack _track({required List<SeasonTier> tiers, int currentTier = 0}) =>
    SeasonTrack(
      hasActiveSeason: true,
      season: SeasonHeader(
        id: 's1',
        number: 1,
        name: 'Trail of Embers',
        theme: 'ember',
        endsAt: DateTime.now().add(const Duration(days: 56)),
        daysLeft: 56,
      ),
      xpPerTier: 600,
      tierCount: tiers.length,
      milestoneTier: tiers.isEmpty ? 25 : tiers.last.tier,
      seasonXp: currentTier * 600,
      currentTier: currentTier,
      xpIntoTier: 0,
      xpToNextTier: 600,
      hasFounderPass: false,
      nextReward:
          const NextReward(tier: 1, label: '+150 Season XP', track: 'Free'),
      tiers: tiers,
    );

Widget _host(SeasonTrack data) => ProviderScope(
      overrides: [
        seasonProvider.overrideWith(() => _FakeSeasonNotifier(data)),
      ],
      child: const MaterialApp(home: SeasonTrackScreen()),
    );

void main() {
  testWidgets('renders every tier row without layout errors', (tester) async {
    final tiers = List.generate(
      25,
      (i) => SeasonTier(
        tier: i + 1,
        isMilestone: i + 1 == 25,
        free: _rv(i == 0 ? 'pending' : 'locked'),
        founder: _rv('locked'),
      ),
    );

    await tester.pumpWidget(_host(_track(tiers: tiers, currentTier: 0)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SEASON 1'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('FOUNDER'), findsOneWidget);
    // The track scrolls, so at least the first several rows must be laid out.
    expect(find.byType(SeasonTierRow), findsWidgets);
    expect(find.text('1'), findsWidgets); // tier-1 badge
  });

  testWidgets('empty tier list does not crash', (tester) async {
    await tester.pumpWidget(_host(_track(tiers: const [])));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('SEASON 1'), findsOneWidget);
    expect(find.byType(SeasonTierRow), findsNothing);
  });

  testWidgets('no active season shows the empty state', (tester) async {
    final none = SeasonTrack(
      hasActiveSeason: false,
      season: null,
      xpPerTier: 0,
      tierCount: 0,
      milestoneTier: 0,
      seasonXp: 0,
      currentTier: 0,
      xpIntoTier: 0,
      xpToNextTier: 0,
      hasFounderPass: false,
      nextReward: null,
      tiers: const [],
    );
    await tester.pumpWidget(_host(none));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('No season is running'), findsOneWidget);
  });
}
