import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/services/shell_overlay_notifier.dart';
import 'package:life_level/features/home/cards/home_adventure_hub.dart';
import 'package:life_level/features/home/providers/adventure_hub_status_provider.dart';
import 'package:life_level/features/unlocks/models/unlock_models.dart';
import 'package:life_level/features/unlocks/providers/unlocks_provider.dart';

UnlockState _u(String key, int order,
        {bool unlocked = true, bool toured = true}) =>
    UnlockState(
        key: key,
        order: order,
        unlocked: unlocked,
        seen: unlocked,
        toured: toured);

void main() {
  testWidgets('locked tiles show their name and a hint, and never open',
      (tester) async {
    final snapshot = UnlocksSnapshot([
      _u('home', 0),
      _u('achievements', 1, unlocked: false),
      _u('chests', 4, unlocked: false),
      _u('talents', 5, toured: false), // fresh: unlocked, tour pending
      _u('bosses', 7, unlocked: false),
      _u('guild', 8, unlocked: false),
    ]);
    final opened = <String>[];
    final sub = ShellOverlayNotifier.stream.listen(opened.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unlocksSnapshotProvider.overrideWithValue(snapshot),
          adventureHubSignalsProvider
              .overrideWith((ref) async => AdventureHubSignals.empty),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeAdventureHub())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Names stay visible so the player sees what's coming.
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Guild'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(4));
    expect(find.text('NEW'), findsOneWidget);

    await tester.tap(find.text('Achievements'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.text('Reach Level 2 to unlock'), findsOneWidget);
    expect(opened, isEmpty);

    // An open tile still opens.
    await tester.tap(find.text('Talents'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(opened, ['talents']);

    // Let the toast time out.
    await tester.pump(const Duration(seconds: 6));
  });
}
