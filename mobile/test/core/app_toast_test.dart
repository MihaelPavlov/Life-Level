import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_level/core/widgets/app_toast.dart';

/// App with a button that runs [fire]; tapping it shows the toast(s).
Future<void> _pump(
    WidgetTester tester, void Function(BuildContext) fire) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  addTearDown(AppToast.dismiss);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => fire(context),
          child: const Text('go'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('go'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('toast text does not inherit the debug fallback style',
      (tester) async {
    await _pump(tester, (c) => AppToast.success(c, '+120 coins claimed!'));

    // The style actually painted, after DefaultTextStyle merging.
    final rich = tester.widget<RichText>(find.descendant(
      of: find.text('+120 coins claimed!'),
      matching: find.byType(RichText),
    ));
    final style = rich.text.style!;
    expect(style.decoration, isNot(TextDecoration.underline));
    expect(style.fontFamily, isNot('monospace'));
  });

  testWidgets('toast stack clears the raised center Map button',
      (tester) async {
    await _pump(tester, (c) => AppToast.info(c, 'Workout logged'));

    final layer = tester.widget<Positioned>(
      find.byKey(const ValueKey('app-toast-layer')),
    );
    expect(layer.bottom, 126);
  });

  testWidgets('shows a title, detail line and action', (tester) async {
    var retried = false;
    await _pump(
      tester,
      (c) => AppToast.error(c, "Couldn't open the chest",
          detail: 'Check your connection and try again.',
          action: ToastAction('Retry', () => retried = true)),
    );
    expect(find.text("Couldn't open the chest"), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
    expect(find.text("Couldn't open the chest"), findsNothing);
  });

  testWidgets('hides itself when its countdown ends', (tester) async {
    await _pump(tester, (c) => AppToast.success(c, 'Avatar updated'));
    expect(find.text('Avatar updated'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Avatar updated'), findsNothing);
  });

  testWidgets('stacks up to three, older ones shrink to one line',
      (tester) async {
    await _pump(tester, (c) {
      AppToast.info(c, 'Heading to Twin Oaks', detail: '14 km');
      AppToast.warning(c, 'Frostpeak is locked', detail: 'Unlocks at 15');
      AppToast.error(c, 'Not enough coins', detail: 'You need 120 more.');
    });
    // All three titles are readable…
    expect(find.text('Heading to Twin Oaks'), findsOneWidget);
    expect(find.text('Frostpeak is locked'), findsOneWidget);
    expect(find.text('Not enough coins'), findsOneWidget);
    // …but only the newest shows its detail line.
    expect(find.text('You need 120 more.'), findsOneWidget);
    expect(find.text('14 km'), findsNothing);
    expect(find.text('Clear all · 3'), findsOneWidget);

    // Tapping a shrunk one opens it.
    await tester.tap(find.text('Heading to Twin Oaks'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('14 km'), findsOneWidget);

    // A fourth pushes the oldest out.
    AppToast.success(tester.element(find.text('go')), 'Avatar updated');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Heading to Twin Oaks'), findsNothing);
    expect(find.text('Avatar updated'), findsOneWidget);

    await tester.tap(find.textContaining('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('Avatar updated'), findsNothing);
  });

  testWidgets('the same message again bumps a counter', (tester) async {
    await _pump(tester, (c) {
      AppToast.error(c, "Couldn't open the chest");
      AppToast.error(c, "Couldn't open the chest");
    });
    expect(find.text("Couldn't open the chest"), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
  });

  testWidgets('a progress toast turns into its result', (tester) async {
    late AppToastHandle handle;
    await _pump(
        tester, (c) => handle = AppToast.progress(c, 'Syncing activities'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // No countdown while loading.
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Syncing activities'), findsOneWidget);

    handle.success('Synced 2 new activities', detail: '+180 XP');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Syncing activities'), findsNothing);
    expect(find.text('Synced 2 new activities'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('swipe dismisses a toast', (tester) async {
    await _pump(tester, (c) => AppToast.info(c, 'Heading to Twin Oaks'));
    await tester.fling(
        find.text('Heading to Twin Oaks'), const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Heading to Twin Oaks'), findsNothing);
  });

  group('cleanMessage', () {
    (String, String?) clean(String m) => AppToast.cleanMessage(m, null);

    test('raw exceptions become plain words', () {
      expect(clean('Failed to open chest: DioException [bad response]'),
          ("Couldn't open chest", 'Check your connection and try again.'));
      expect(clean('DioException [connection error]'),
          ('Something went wrong', 'Check your connection and try again.'));
      expect(clean('Exception: Not enough coins'), ('Not enough coins', null));
      expect(clean('Failed: unknown error'),
          ('Something went wrong', 'Please try again.'));
    });

    test('developer notes are stripped', () {
      expect(
          clean('No branches found for Twin Oaks. (0 matched - check logs.)'),
          ('No branches found for Twin Oaks.', null));
      expect(clean("Region chest rewards aren't live yet — no backend for it."),
          ("Region chest rewards aren't live yet", null));
    });

    test('a second line becomes the detail', () {
      expect(clean('XP Storm is live!\nDouble XP for the next 2 hours.'),
          ('XP Storm is live!', 'Double XP for the next 2 hours.'));
    });

    test('normal messages pass through', () {
      expect(clean('+120 coins claimed!'), ('+120 coins claimed!', null));
    });
  });
}
