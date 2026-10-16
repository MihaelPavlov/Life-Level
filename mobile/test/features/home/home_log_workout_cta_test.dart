import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/activity/log_activity_screen.dart';
import 'package:life_level/features/home/cards/home_log_workout_cta.dart';

void main() {
  testWidgets('live tracker is hidden while manual logging remains available',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: HomeLogWorkoutCta(showTracker: true)),
      ),
    ));

    expect(find.text('Track workout'), findsNothing);
    expect(find.text('Continue workout'), findsNothing);
    expect(find.text('Log workout'), findsOneWidget);

    await tester.tap(find.text('Log workout'));
    await tester.pumpAndSettle();

    expect(find.byType(LogActivityScreen), findsOneWidget);
  });
}
