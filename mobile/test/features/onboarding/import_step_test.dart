import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/theme/app_theme.dart';
import 'package:life_level/features/character/setup/setup_resume_service.dart';
import 'package:life_level/features/onboarding/models/onboarding_models.dart';
import 'package:life_level/features/onboarding/onboarding_controller.dart';
import 'package:life_level/features/onboarding/screens/import_step.dart';

List<ImportedWorkout> _workouts(int n) => List.generate(
      n,
      (index) => ImportedWorkout(
        type: index == n - 1 ? 'swimming' : 'walking',
        performedAt: DateTime(2026, 10, 7).subtract(Duration(days: index)),
        durationMinutes: 30 + index,
        distanceKm: index == n - 1 ? 1.8 : 5 + index.toDouble(),
        xp: 50 + index,
      ),
    );

Future<void> _pump(WidgetTester tester, List<ImportedWorkout> workouts,
    {Size size = const Size(390, 844)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = OnboardingController(
    const SetupResumeState(
      step: SetupStep.importing,
      ringItems: [],
      source: OnboardingSource.strava,
    ),
  )..importResult = OnboardingImportResult(
      source: OnboardingSource.strava,
      imported: workouts.length,
      skipped: 0,
      rejectedManualCount: 2,
      totalMinutes: workouts.fold(0, (sum, item) => sum + item.durationMinutes),
      totalKm: workouts.fold(0, (sum, item) => sum + item.distanceKm),
      totalAdventureDistanceKm: 20,
      totalXp: workouts.fold(0, (sum, item) => sum + item.xp),
      leveledUp: true,
      previousLevel: 1,
      newLevel: 2,
      windowStart: DateTime(2026, 9, 7),
      windowEnd: DateTime(2026, 10, 7),
      workouts: workouts,
      errors: const [],
    );

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: true),
        child: OnboardingScope(
          controller: controller,
          child: const ImportStep(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('up to four workouts all show, with no "more" row',
      (tester) async {
    await _pump(tester, _workouts(4));

    expect(find.text('Walking · 5.0 km'), findsOneWidget);
    expect(find.text('Swimming · 1.8 km'), findsOneWidget);
    expect(find.textContaining('more workout'), findsNothing);
    expect(find.text('WORKOUTS'), findsOneWidget);
    expect(
        find.text('2 manual entries skipped — only tracked workouts earn XP'),
        findsOneWidget);
    expect(find.text('SEE MY LEVEL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('more than four: three rows, "+N more" opens the full list',
      (tester) async {
    final workouts = _workouts(8);
    await _pump(tester, workouts);

    expect(find.text('Walking · 5.0 km'), findsOneWidget);
    expect(find.text('Walking · 7.0 km'), findsOneWidget);
    expect(find.text('Walking · 8.0 km'), findsNothing); // 4th newest
    expect(find.text('Swimming · 1.8 km'), findsNothing);
    final hiddenXp = workouts.skip(3).fold<int>(0, (a, w) => a + w.xp);
    expect(find.text('+5 more workouts'), findsOneWidget);
    expect(find.text('+$hiddenXp'), findsOneWidget);
    expect(find.text('SEE MY LEVEL'), findsOneWidget);

    await tester.tap(find.text('+5 more workouts'));
    await tester.pumpAndSettle();

    expect(find.text('All imported workouts'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('LAST WEEK'), findsOneWidget);
    expect(find.text('Swimming · 1.8 km'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('All imported workouts'), findsNothing);
  });

  testWidgets('short phones fit without overflow', (tester) async {
    await _pump(tester, _workouts(8), size: const Size(360, 640));
    expect(find.text('+5 more workouts'), findsOneWidget);
    expect(find.text('SEE MY LEVEL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
