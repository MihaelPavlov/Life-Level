import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/shell/boot/boot_loader.dart';
import 'package:life_level/core/shell/boot/boot_readiness.dart';

BootReadiness _r(List<BootStepState> s) => BootReadiness({
      for (final (i, step) in BootStep.values.indexed) step: s[i],
    });

const _l = BootStepState.loading;
const _d = BootStepState.done;
const _f = BootStepState.failed;

void main() {
  group('foldBootStep', () {
    test('done only when every source has data', () {
      expect(foldBootStep([const AsyncData(1), const AsyncData(2)]),
          BootStepState.done);
      expect(foldBootStep([const AsyncData(1), const AsyncLoading<int>()]),
          BootStepState.loading);
    });

    test('an error with no data marks the row failed', () {
      expect(
          foldBootStep([
            const AsyncData(1),
            const AsyncError<int>('boom', StackTrace.empty),
          ]),
          BootStepState.failed);
    });

    test('a source reloading after an error is still loading, not failed',
        () {
      // What a provider looks like when it's invalidated after a failed
      // fetch: loading again, with the old error carried along.
      final reloading = const AsyncLoading<int>().copyWithPrevious(
          const AsyncError<int>('401', StackTrace.empty));
      expect(reloading.hasError, isTrue);
      expect(foldBootStep([const AsyncData(1), reloading]),
          BootStepState.loading);
    });
  });

  test('ready only when all four rows are done', () {
    expect(_r([_d, _d, _d, _l]).allDone, isFalse);
    expect(_r([_d, _d, _d, _d]).allDone, isTrue);
    expect(_r([_d, _f, _d, _d]).anyFailed, isTrue);
    expect(_r([_d, _d, _l, _l]).doneCount, 2);
  });

  group('BootLoaderOverlay', () {
    late StateController<BootReadiness> readiness;

    // The exit fade needs frames to advance; the logo pulse never settles.
    Future<void> frames(WidgetTester tester, [int n = 12]) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> pump(WidgetTester tester, VoidCallback onFinished) async {
      final state = StateProvider<BootReadiness>((_) => _r([_l, _l, _l, _l]));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bootReadinessProvider.overrideWith((ref) => ref.watch(state)),
        ],
        child: Consumer(builder: (context, ref, _) {
          readiness = ref.read(state.notifier);
          return MaterialApp(
            home: Scaffold(body: BootLoaderOverlay(onFinished: onFinished)),
          );
        }),
      ));
    }

    testWidgets('waits for every row, then finishes', (tester) async {
      var finished = false;
      await pump(tester, () => finished = true);
      expect(find.text('Preparing your world'), findsOneWidget);
      expect(bootLoaderShowing, isTrue);

      readiness.state = _r([_d, _d, _d, _l]);
      await tester.pump(const Duration(seconds: 1));
      expect(finished, isFalse);

      readiness.state = _r([_d, _d, _d, _d]);
      await frames(tester);
      expect(finished, isTrue);
      expect(bootLoaderShowing, isFalse);
    });

    testWidgets('stays at least the minimum time', (tester) async {
      var finished = false;
      await pump(tester, () => finished = true);
      readiness.state = _r([_d, _d, _d, _d]);
      await tester.pump(const Duration(milliseconds: 300));
      expect(finished, isFalse);
      await frames(tester, 20);
      expect(finished, isTrue);
    });

    testWidgets('slow load offers Try again, then Continue anyway',
        (tester) async {
      var finished = false;
      await pump(tester, () => finished = true);
      await tester.pump(const Duration(seconds: 9));
      expect(find.text('Taking longer than usual.'), findsOneWidget);
      expect(find.text('Continue anyway'), findsNothing);

      await tester.pump(const Duration(seconds: 12));
      expect(find.text('Continue anyway'), findsOneWidget);
      await tester.tap(find.text('Continue anyway'));
      await frames(tester);
      expect(finished, isTrue);
    });

    testWidgets('a failed row shows the error message', (tester) async {
      await pump(tester, () {});
      readiness.state = _r([_d, _f, _l, _l]);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Something didn\'t load.'), findsOneWidget);
      // Let the pending timers fire before the test ends.
      await tester.pump(const Duration(seconds: 21));
    });
  });
}
