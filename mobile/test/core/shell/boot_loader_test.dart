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

    test('a source reloading after an error is still loading, not failed', () {
      // What a provider looks like when it's invalidated after a failed
      // fetch: loading again, with the old error carried along.
      final reloading = const AsyncLoading<int>()
          .copyWithPrevious(const AsyncError<int>('401', StackTrace.empty));
      expect(reloading.hasError, isTrue);
      expect(
          foldBootStep([const AsyncData(1), reloading]), BootStepState.loading);
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

    Future<void> pump(WidgetTester tester, VoidCallback onFinished,
        {void Function(WidgetRef, BootStep)? retryStep}) async {
      final state = StateProvider<BootReadiness>((_) => _r([_l, _l, _l, _l]));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bootReadinessProvider.overrideWith((ref) => ref.watch(state)),
        ],
        child: Consumer(builder: (context, ref, _) {
          readiness = ref.read(state.notifier);
          return MaterialApp(
            home: Scaffold(
                body: BootLoaderOverlay(
                    onFinished: onFinished, retryStep: retryStep)),
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

    testWidgets('slow load offers actions after 20 seconds', (tester) async {
      var finished = false;
      await pump(tester, () => finished = true);
      await tester.pump(const Duration(seconds: 9));
      expect(find.text('Taking longer than usual.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Continue'), findsNothing);

      await tester.pump(const Duration(seconds: 12));
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await frames(tester);
      expect(finished, isTrue);
    });

    testWidgets('a transient failure retries without asking the player',
        (tester) async {
      var retries = 0;
      var finished = false;
      await pump(tester, () => finished = true, retryStep: (_, step) {
        expect(step, BootStep.rewards);
        retries++;
        readiness.state = _r([_d, _d, _d, _l]);
        readiness.state = _r([_d, _d, _d, _d]);
      });
      readiness.state = _r([_d, _d, _d, _f]);
      await tester.pump();
      expect(find.byIcon(Icons.priority_high_rounded), findsNothing);
      expect(find.text('Try again'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await frames(tester);
      expect(retries, 1);
      expect(finished, isTrue);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('persistent failure retries three times, then offers choices',
        (tester) async {
      var retries = 0;
      var finished = false;
      await pump(tester, () => finished = true, retryStep: (_, step) {
        expect(step, BootStep.rewards);
        retries++;
        readiness.state = _r([_d, _d, _d, _l]);
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          readiness.state = _r([_d, _d, _d, _f]);
        });
      });
      readiness.state = _r([_d, _d, _d, _f]);
      await tester.pump();
      for (final seconds in [1, 2, 4]) {
        await tester.pump(Duration(seconds: seconds));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byIcon(Icons.priority_high_rounded), findsNothing);
        if (retries < 3) expect(find.text('Try again'), findsNothing);
      }
      expect(retries, 3);
      expect(find.text('Something didn\'t load.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await frames(tester);
      expect(finished, isTrue);
    });

    testWidgets('Try again starts a fresh attempt after automatic retries',
        (tester) async {
      var retries = 0;
      var finished = false;
      await pump(tester, () => finished = true, retryStep: (_, step) {
        expect(step, BootStep.rewards);
        retries++;
        readiness.state = _r([_d, _d, _d, _l]);
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          readiness.state = _r([_d, _d, _d, retries == 4 ? _d : _f]);
        });
      });
      readiness.state = _r([_d, _d, _d, _f]);
      await tester.pump();
      for (final seconds in [1, 2, 4]) {
        await tester.pump(Duration(seconds: seconds));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(retries, 3);
      await tester.tap(find.text('Try again'));
      await tester.pump(const Duration(milliseconds: 100));
      await frames(tester);
      expect(retries, 4);
      expect(finished, isTrue);
    });

    testWidgets('leaving the loader cancels its pending automatic retry',
        (tester) async {
      var retries = 0;
      await pump(tester, () {}, retryStep: (_, __) => retries++);
      readiness.state = _r([_d, _d, _d, _f]);
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(retries, 0);
    });
  });
}
