import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/activity/models/activity_models.dart';
import 'package:life_level/features/activity/tracking/workout_tracker.dart';

void main() {
  test('paused time is excluded and coordinates never leave the phone', () {
    final now = DateTime.now().toUtc();
    final session = TrackedWorkout(
      id: '90d56a99-2ebf-4816-a3b3-7cb015de9c63',
      type: ActivityType.running,
      startedAt: now.subtract(const Duration(minutes: 25)),
      resumedAt: now.subtract(const Duration(minutes: 5)),
      accumulatedSeconds: 600,
      distanceMeters: 2500,
      gpsSamples: 8,
      lastLatitude: 42.0,
      lastLongitude: 23.0,
    );

    expect(session.activeSeconds, inInclusiveRange(900, 902));
    final request = session.toApiJson();
    expect(request['distanceMeters'], 2500);
    expect(request.containsKey('lastLatitude'), isFalse);
    expect(request.containsKey('lastLongitude'), isFalse);
  });
}
