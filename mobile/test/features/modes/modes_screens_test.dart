import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/activity/models/activity_models.dart';
import 'package:life_level/features/activity/providers/activity_provider.dart';
import 'package:life_level/features/character/models/character_profile.dart';
import 'package:life_level/features/character/providers/character_provider.dart';
import 'package:life_level/features/modes/burn_chain/burn_chain_provider.dart';
import 'package:life_level/features/modes/burn_chain/burn_chain_rules.dart';
import 'package:life_level/features/modes/burn_chain/burn_chain_screen.dart';
import 'package:life_level/features/modes/modes_screen.dart';
import 'package:life_level/features/modes/treasure_delve/delve_engine.dart';
import 'package:life_level/features/modes/treasure_delve/delve_provider.dart';
import 'package:life_level/features/modes/treasure_delve/delve_run_screen.dart';
import 'package:life_level/features/modes/treasure_delve/treasure_delve_screen.dart';

const _profile = CharacterProfile(
  username: 'Hero',
  avatarEmoji: null,
  className: null,
  classEmoji: null,
  rank: 'Novice',
  level: 5,
  xp: 100,
  xpForCurrentLevel: 0,
  xpForNextLevel: 200,
  strength: 12,
  endurance: 10,
  agility: 42,
  flexibility: 7,
  stamina: 11,
  weeklyRuns: 2,
  weeklyDistanceKm: 8,
  weeklyXpEarned: 300,
  currentStreak: 4,
  availableStatPoints: 0,
  power: 125,
  attack: 32,
  health: 210,
  defense: 18,
);

class _Profile extends CharacterNotifier {
  @override
  Future<CharacterProfile> build() async => _profile;
}

class _Chain extends BurnChainNotifier {
  final BurnChainState chain;
  _Chain(this.chain);
  @override
  Future<BurnChainView> build() async =>
      BurnChainView(chain, chain.links.length);
}

class _Run extends DelveRunNotifier {
  final DelveRun run;
  _Run(this.run);
  @override
  DelveRun? build() => run;
}

final _start = DateTime.now().toUtc().subtract(const Duration(hours: 3));

ChainLink _link(int kcal, ChainLinkKind kind, int? bar, int hour) => ChainLink(
      activityId: '$hour',
      type: 'Running',
      durationMinutes: 30,
      calories: kcal,
      loggedAt: _start.add(Duration(hours: hour)),
      kind: kind,
      barBefore: bar,
    );

final _live = BurnChainState(
  phase: BurnChainPhase.live,
  startedAt: _start,
  links: [
    _link(200, ChainLinkKind.base, null, 1),
    _link(320, ChainLinkKind.beat, 200, 2),
  ],
);

final _ended = BurnChainState(
  phase: BurnChainPhase.ended,
  startedAt: _start,
  endReason: BurnChainEndReason.broken,
  links: [
    _link(200, ChainLinkKind.base, null, 1),
    _link(320, ChainLinkKind.beat, 200, 2),
    _link(300, ChainLinkKind.breaker, 320, 3),
  ],
);

const _status = DelveStatus(
  runsEarned: 2,
  runsUsed: 0,
  featured: DelveStat.str,
  bestRun: 180,
);

Future<void> _pump(WidgetTester tester, Widget screen,
    {BurnChainState? chain, DelveRun? run}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      characterProfileProvider.overrideWith(_Profile.new),
      activityHistoryProvider
          .overrideWith((_) async => const <ActivityHistoryDto>[]),
      burnChainProvider
          .overrideWith(() => _Chain(chain ?? BurnChainState.idle)),
      delveStatusProvider.overrideWith((_) async => _status),
      if (run != null) delveRunProvider.overrideWith(() => _Run(run)),
    ],
    child: MaterialApp(home: screen),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

DelveEngine get _engine =>
    DelveEngine(profile: _profile, featured: DelveStat.str);

void main() {
  testWidgets('Modes tab shows both banners', (tester) async {
    await _pump(tester, const ModesScreen(), chain: _live);
    expect(find.text('Burn Chain'), findsOneWidget);
    expect(find.text('Treasure Delve'), findsOneWidget);
    expect(find.textContaining('Beat 320 kcal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burn Chain intro', (tester) async {
    await _pump(tester, const BurnChainScreen());
    expect(find.text('START 24H CHAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burn Chain live', (tester) async {
    await _pump(tester, const BurnChainScreen(), chain: _live);
    expect(find.text('BAR TO BEAT'), findsOneWidget);
    expect(find.text('320'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burn Chain ended', (tester) async {
    await _pump(tester, const BurnChainScreen(), chain: _ended);
    expect(find.text('Collect 228 coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Burn Chain ×2 sheet', (tester) async {
    await _pump(tester, const Scaffold());
    final context = tester.element(find.byType(Scaffold));
    showBurnChainBeat(context, _live.links.last, _live);
    await tester.pumpAndSettle();
    expect(find.text('+128'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Treasure Delve entrance', (tester) async {
    await _pump(tester, const TreasureDelveScreen());
    expect(find.text('ENTER THE VAULT'), findsOneWidget);
    expect(find.text('Uses 1 of your 2 runs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delve run: every phase renders', (tester) async {
    final e = _engine;
    final start = e.start();
    final challenge = e.choose(start, start.options[1]);
    final decision = e.attempt(e.choose(start, start.options[0]));
    final result = e.bank(decision);

    for (final (run, expected) in [
      (start, 'Choose your path'),
      (challenge, 'Pick another path'),
      (decision, 'Continue deeper'),
      (result, 'VAULT BANKED'),
    ]) {
      // A fresh ProviderScope per phase.
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, const DelveRunScreen(), run: run);
      expect(find.text(expected), findsOneWidget, reason: '$expected phase');
      expect(tester.takeException(), isNull);
    }
  });
}
