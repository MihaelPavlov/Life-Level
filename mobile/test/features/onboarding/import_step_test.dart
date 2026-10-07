import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/theme/app_theme.dart';
import 'package:life_level/features/character/setup/setup_resume_service.dart';
import 'package:life_level/features/onboarding/models/onboarding_models.dart';
import 'package:life_level/features/onboarding/onboarding_controller.dart';
import 'package:life_level/features/onboarding/screens/import_step.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('workout history scrolls while the continue button stays pinned',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final workouts = List.generate(
      8,
      (index) => ImportedWorkout(
        type: index == 7 ? 'swimming' : 'walking',
        performedAt: DateTime(2026, 10, 7).subtract(Duration(days: index)),
        durationMinutes: 30 + index,
        distanceKm: index == 7 ? 1.8 : 5 + index.toDouble(),
        xp: 50 + index,
      ),
    );
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
        rejectedManualCount: 0,
        totalMinutes:
            workouts.fold(0, (sum, item) => sum + item.durationMinutes),
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
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: OnboardingScope(
            controller: controller,
            child: const ImportStep(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SEE MY LEVEL'), findsOneWidget);
    expect(find.text('Swimming · 1.8 km'), findsNothing);

    await tester.drag(find.byType(AnimatedList), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Swimming · 1.8 km'), findsOneWidget);
    expect(find.text('SEE MY LEVEL'), findsOneWidget);
  });
}
