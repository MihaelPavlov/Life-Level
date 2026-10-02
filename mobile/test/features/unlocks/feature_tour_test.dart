import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/constants/app_colors.dart';
import 'package:life_level/core/constants/app_icons.dart';
import 'package:life_level/features/unlocks/tour/feature_tour.dart';
import 'package:life_level/features/unlocks/tour/tour_step.dart';
import 'package:life_level/features/unlocks/tour/tour_target.dart';

TourStep _step(String id, {String? tap}) => TourStep(
      targetId: id,
      icon: AppIcons.navHome,
      eyebrow: 'STOP $id',
      title: 'Title $id',
      body: 'Body with **bold** words.',
      tapLabel: tap,
    );

class _Harness extends StatelessWidget {
  final VoidCallback onClaim;
  const _Harness({required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const SizedBox(height: 120),
            const TourTarget(id: 'a', child: SizedBox(height: 60, width: 200)),
            const SizedBox(height: 40),
            TourTarget(
              id: 'claim',
              child: ElevatedButton(
                  onPressed: onClaim, child: const Text('Claim all')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pumps frames until [done] completes (the tour polls and waits a bit).
Future<T> _drive<T>(WidgetTester tester, Future<T> done) async {
  T? result;
  var finished = false;
  done.then((v) {
    result = v;
    finished = true;
  });
  for (var i = 0; i < 400 && !finished; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finished, isTrue, reason: 'tour never finished');
  return result as T;
}

Future<void> _pumpFor(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('Next, then a tap stop that runs the real action',
      (tester) async {
    var claims = 0;
    var completedWith = <TourOutcome>[];
    await tester.pumpWidget(_Harness(onClaim: () => claims++));

    final ctx = tester.element(find.byType(Scaffold));
    final run = FeatureTour.run(
      ctx,
      name: 'Achievements',
      color: AppColors.orange,
      steps: [_step('a'), _step('claim', tap: 'TAP CLAIM ALL')],
      onComplete: (o) async {
        completedWith.add(o);
        return 25;
      },
    );
    await _pumpFor(tester, 400);
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await _pumpFor(tester, 400);
    expect(find.text('TAP CLAIM ALL'), findsOneWidget);

    // The tap goes through the spotlight hole to the real button.
    await tester.tap(find.text('Claim all'), warnIfMissed: false);
    final outcome = await _drive(tester, run);

    expect(claims, 1);
    expect(outcome, TourOutcome.finished);
    expect(completedWith, [TourOutcome.finished]);
    expect(FeatureTour.isRunning, isFalse);
  });

  testWidgets('Skip ends the tour early', (tester) async {
    await tester.pumpWidget(_Harness(onClaim: () {}));
    final ctx = tester.element(find.byType(Scaffold));
    final run = FeatureTour.run(
      ctx,
      name: 'X',
      color: AppColors.blue,
      steps: [_step('a'), _step('claim')],
    );
    await _pumpFor(tester, 400);
    await tester.tap(find.text('Skip'));
    expect(await _drive(tester, run), TourOutcome.skipped);
  });

  testWidgets('a stop whose widget is missing is skipped', (tester) async {
    await tester.pumpWidget(_Harness(onClaim: () {}));
    final ctx = tester.element(find.byType(Scaffold));
    final run = FeatureTour.run(
      ctx,
      name: 'X',
      color: AppColors.blue,
      steps: [_step('a'), _step('nowhere'), _step('claim')],
    );
    await _pumpFor(tester, 400);
    await tester.tap(find.text('NEXT'));
    await _pumpFor(tester, 1800);
    expect(find.text('Title claim'), findsOneWidget);
    await tester.tap(find.text('GOT IT'));
    expect(await _drive(tester, run), TourOutcome.finished);
  });

  testWidgets('no stop on screen at all aborts without a trace',
      (tester) async {
    await tester.pumpWidget(_Harness(onClaim: () {}));
    final ctx = tester.element(find.byType(Scaffold));
    final run = FeatureTour.run(
      ctx,
      name: 'X',
      color: AppColors.blue,
      steps: [_step('nowhere')],
    );
    expect(await _drive(tester, run), TourOutcome.aborted);
    expect(find.text('FEATURE EXPLORED'), findsNothing);
  });
}
