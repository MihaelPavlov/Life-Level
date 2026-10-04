import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/unlocks/models/unlock_models.dart';
import 'package:life_level/features/unlocks/providers/unlocks_provider.dart';
import 'package:life_level/features/unlocks/unlock_coordinator.dart';
import 'package:life_level/features/unlocks/tour/tour_target.dart';

/// Serves a fixed chain and records what the coordinator marks.
class _FakeUnlocks extends UnlocksNotifier {
  _FakeUnlocks(this.initial, this.seen);
  final UnlocksSnapshot initial;
  final List<String> seen;

  @override
  Future<UnlocksSnapshot> build() async => initial;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markSeen(String key) async {
    seen.add(key);
    state = AsyncData(state.value!.update(key, (u) => u.copyWith(seen: true)));
  }

  @override
  Future<int> markToured(String key) async {
    state = AsyncData(
        state.value!.update(key, (u) => u.copyWith(seen: true, toured: true)));
    return 25;
  }
}

UnlockState _u(String key, int order,
        {bool unlocked = true, bool seen = true, bool toured = true}) =>
    UnlockState(
        key: key, order: order, unlocked: unlocked, seen: seen, toured: toured);

Future<void> _pumpFor(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<({List<String> seen, List<String> opened})> _mount(
  WidgetTester tester,
  UnlocksSnapshot snapshot,
) async {
  final seen = <String>[];
  final opened = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        unlocksProvider.overrideWith(() => _FakeUnlocks(snapshot, seen)),
      ],
      child: MaterialApp(
        home: UnlockCoordinator(
          canInterrupt: () => true,
          prepareCeremony: (_) async {},
          openFeature: (key) async => opened.add(key),
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    ),
  );
  return (seen: seen, opened: opened);
}

void main() {
  testWidgets(
      'reveals an offscreen Hub icon before showing the blurred ceremony',
      (tester) async {
    final vertical = ScrollController();
    final horizontal = ScrollController();
    final prepared = <String>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        unlocksProvider.overrideWith(() => _FakeUnlocks(
            UnlocksSnapshot([
              _u('home', 0),
              _u('achievements', 1, seen: false, toured: false),
            ]),
            [])),
      ],
      child: MaterialApp(
        home: UnlockCoordinator(
          canInterrupt: () => true,
          prepareCeremony: (key) async => prepared.add(key),
          openFeature: (_) async {},
          child: Scaffold(
            body: SingleChildScrollView(
              controller: vertical,
              child: Column(children: [
                const SizedBox(height: 900),
                SingleChildScrollView(
                  controller: horizontal,
                  scrollDirection: Axis.horizontal,
                  child: const Row(children: [
                    SizedBox(width: 1000),
                    TourTarget(
                      id: 'icon.achievements',
                      child: SizedBox(width: 56, height: 56),
                    ),
                    SizedBox(width: 500),
                  ]),
                ),
                const SizedBox(height: 500),
              ]),
            ),
          ),
        ),
      ),
    ));

    await _pumpFor(tester, 1600);
    expect(prepared, ['achievements']);
    expect(vertical.offset, greaterThan(0));
    expect(horizontal.offset, greaterThan(0));
    expect(find.text('NEW FEATURE UNLOCKED'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
    final icon = TourTargets.rectOf('icon.achievements')!;
    expect(icon.left, greaterThanOrEqualTo(0));
    expect(
        icon.right,
        lessThanOrEqualTo(
            tester.view.physicalSize.width / tester.view.devicePixelRatio));
    await tester.pumpWidget(const SizedBox.shrink());
    vertical.dispose();
    horizontal.dispose();
  });

  testWidgets('Later marks the unlock seen and opens nothing', (tester) async {
    final r = await _mount(
        tester,
        UnlocksSnapshot([
          _u('home', 0),
          _u('achievements', 1, seen: false, toured: false),
        ]));
    await _pumpFor(tester, 3400);
    expect(find.text('NEW FEATURE UNLOCKED'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    // A lone unlock has no "1 of 2" counter.
    expect(find.textContaining('UNLOCK 1 OF'), findsNothing);

    await tester.tap(find.text('Later · tour runs on first visit'));
    await _pumpFor(tester, 1500);

    expect(r.seen, ['achievements']);
    expect(r.opened, isEmpty);
    expect(find.text('NEW FEATURE UNLOCKED'), findsNothing);
  });

  testWidgets(
      'one level\'s two unlocks play as a queue: 1 of 2, Show me, bridge, 2 of 2',
      (tester) async {
    final r = await _mount(
        tester,
        UnlocksSnapshot([
          _u('home', 0),
          _u('achievements', 2, seen: false, toured: false),
          _u('gear', 3, seen: false, toured: false),
        ]));
    await _pumpFor(tester, 3400);
    expect(find.text('UNLOCK 1 OF 2'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Gear'), findsNothing);
    expect(find.text('Later · 1 more unlock waiting'), findsOneWidget);

    await tester.tap(find.text('SHOW ME ACHIEVEMENTS'));
    await _pumpFor(tester, 1500);
    expect(r.seen, ['achievements']);
    expect(r.opened, ['achievements']);

    // The bridge hands over to the second unlock.
    await _pumpFor(tester, 400);
    expect(find.text('1 MORE UNLOCK'), findsOneWidget);
    await _pumpFor(tester, 4000);
    expect(find.text('UNLOCK 2 OF 2'), findsOneWidget);
    expect(find.text('Gear'), findsOneWidget);
    await tester.tap(find.text('Later · tour runs on first visit'));
    await _pumpFor(tester, 1500);
    expect(r.seen, ['achievements', 'gear']);
  });

  testWidgets('a new player gets the Home tour, with no ceremony',
      (tester) async {
    final r = await _mount(
        tester, UnlocksSnapshot([_u('home', 0, seen: false, toured: false)]));
    await _pumpFor(tester, 1800);
    expect(find.text('NEW FEATURE UNLOCKED'), findsNothing);
    expect(r.opened.first, 'home');
  });

  testWidgets('waits while something else is on screen', (tester) async {
    var free = false;
    final seen = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unlocksProvider.overrideWith(() => _FakeUnlocks(
              UnlocksSnapshot([
                _u('achievements', 1, seen: false, toured: false),
              ]),
              seen)),
        ],
        child: MaterialApp(
          home: UnlockCoordinator(
            canInterrupt: () => free,
            prepareCeremony: (_) async {},
            openFeature: (_) async {},
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );
    await _pumpFor(tester, 2500);
    expect(find.text('NEW FEATURE UNLOCKED'), findsNothing);

    free = true;
    await _pumpFor(tester, 4500);
    expect(find.text('NEW FEATURE UNLOCKED'), findsOneWidget);
    await tester.tap(find.text('Later · tour runs on first visit'));
    await _pumpFor(tester, 3000);
  });
}
