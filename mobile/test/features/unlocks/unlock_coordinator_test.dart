import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/unlocks/models/unlock_models.dart';
import 'package:life_level/features/unlocks/providers/unlocks_provider.dart';
import 'package:life_level/features/unlocks/unlock_coordinator.dart';

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
          openFeature: (key) async => opened.add(key),
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    ),
  );
  return (seen: seen, opened: opened);
}

void main() {
  testWidgets('Later marks the unlock seen and opens nothing', (tester) async {
    final r = await _mount(
        tester,
        UnlocksSnapshot([
          _u('home', 0),
          _u('achievements', 1, seen: false, toured: false),
        ]));
    await _pumpFor(tester, 2400);
    expect(find.text('NEW FEATURE UNLOCKED'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);

    await tester.tap(find.text('Later · tour runs on first visit'));
    await _pumpFor(tester, 1500);

    expect(r.seen, ['achievements']);
    expect(r.opened, isEmpty);
    expect(find.text('NEW FEATURE UNLOCKED'), findsNothing);
  });

  testWidgets('Show me opens the feature; ceremonies play one at a time',
      (tester) async {
    final r = await _mount(
        tester,
        UnlocksSnapshot([
          _u('home', 0),
          _u('achievements', 1, seen: false, toured: false),
          _u('talents', 5, seen: false, toured: false),
        ]));
    await _pumpFor(tester, 2400);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Talents'), findsNothing);

    await tester.tap(find.text('SHOW ME ACHIEVEMENTS'));
    await _pumpFor(tester, 1500);
    expect(r.seen, ['achievements']);
    expect(r.opened, ['achievements']);

    // The next one follows.
    await _pumpFor(tester, 3500);
    expect(find.text('Talents'), findsOneWidget);
    await tester.tap(find.text('Later · tour runs on first visit'));
    await _pumpFor(tester, 1500);
    expect(r.seen, ['achievements', 'talents']);
  });

  testWidgets('a new player gets the Home tour, with no ceremony',
      (tester) async {
    final r = await _mount(
        tester, UnlocksSnapshot([_u('home', 0, seen: false, toured: false)]));
    await _pumpFor(tester, 500);
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
