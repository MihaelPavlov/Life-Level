import 'dart:async';

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

class _DelayedClaimSeasonNotifier extends SeasonNotifier {
  _DelayedClaimSeasonNotifier(this.data);

  final SeasonTrack data;

  final claimCompleter = Completer<List<SeasonClaimResult>>();
  int claimCalls = 0;

  @override
  Future<SeasonTrack> build() async => data;

  @override
  Future<List<SeasonClaimResult>> claimAvailable() {
    claimCalls++;
    return claimCompleter.future;
  }
}

class _RefreshingClaimSeasonNotifier extends SeasonNotifier {
  _RefreshingClaimSeasonNotifier(this.initial, this.fresh);

  final SeasonTrack initial;
  final SeasonTrack fresh;

  @override
  Future<SeasonTrack> build() async => initial;

  @override
  Future<List<SeasonClaimResult>> claimAvailable() async {
    state = AsyncValue.data(fresh);
    return const [
      SeasonClaimResult(
        tier: 1,
        track: 'Free',
        label: '+250 XP',
        xpAwarded: 250,
        leveledUp: false,
        newLevel: null,
        grantedItemName: null,
        grantedTitleKey: null,
      ),
      SeasonClaimResult(
        tier: 2,
        track: 'Free',
        label: '+250 XP',
        xpAwarded: 250,
        leveledUp: false,
        newLevel: null,
        grantedItemName: null,
        grantedTitleKey: null,
      ),
      SeasonClaimResult(
        tier: 3,
        track: 'Free',
        label: '+250 XP',
        xpAwarded: 250,
        leveledUp: false,
        newLevel: null,
        grantedItemName: null,
        grantedTitleKey: null,
      ),
    ];
  }
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

Widget _hostWithNotifier(
  SeasonNotifier notifier, {
  bool disableAnimations = true,
}) =>
    ProviderScope(
      overrides: [seasonProvider.overrideWith(() => notifier)],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: const SeasonTrackScreen(),
        ),
      ),
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
    const none = SeasonTrack(
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
      tiers: [],
    );
    await tester.pumpWidget(_host(none));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('No season is running'), findsOneWidget);
  });

  testWidgets('rapid reward taps send one claim and reveal immediately',
      (tester) async {
    final notifier = _DelayedClaimSeasonNotifier(
      _track(
        currentTier: 1,
        tiers: [
          SeasonTier(
            tier: 1,
            isMilestone: false,
            free: _rv('ready'),
            founder: _rv('locked'),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_hostWithNotifier(notifier));
    await tester.pumpAndSettle();

    final collect = find.ancestor(
      of: find.text('Ready · tap to collect'),
      matching: find.byType(InkWell),
    );
    await tester.tap(collect);
    await tester.pump();

    expect(notifier.claimCalls, 1);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    notifier.claimCompleter.complete(const [
      SeasonClaimResult(
        tier: 1,
        track: 'Free',
        label: '+250 XP',
        xpAwarded: 250,
        leveledUp: false,
        newLevel: null,
        grantedItemName: null,
        grantedTitleKey: null,
      ),
    ]);
    await tester.pump();
    expect(notifier.claimCalls, 1);
  });

  testWidgets('multi-claim animations do not update the viewport reentrantly',
      (tester) async {
    SeasonTrack withState(String claimedState) => _track(
          currentTier: 3,
          tiers: [
            SeasonTier(
              tier: 1,
              isMilestone: false,
              free: _rv(claimedState),
              founder: _rv('locked'),
            ),
            SeasonTier(
              tier: 2,
              isMilestone: false,
              free: _rv(claimedState),
              founder: _rv('locked'),
            ),
            SeasonTier(
              tier: 3,
              isMilestone: false,
              free: _rv(claimedState),
              founder: _rv('locked'),
            ),
            SeasonTier(
              tier: 4,
              isMilestone: true,
              free: _rv('pending'),
              founder: _rv('locked'),
            ),
          ],
        );
    final notifier = _RefreshingClaimSeasonNotifier(
      withState('ready'),
      withState('received'),
    );

    await tester.pumpWidget(
      _hostWithNotifier(notifier, disableAnimations: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ready · tap to collect').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('season-tier-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('season-tier-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('season-tier-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('season-tier-4')), findsOneWidget);
  });
}
