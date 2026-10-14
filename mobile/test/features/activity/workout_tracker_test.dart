import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
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

  test('short GPS steps accumulate past the accuracy threshold', () {
    final now = DateTime.now().toUtc();
    final session = TrackedWorkout(
      id: '01841fb0-3bd4-4b4a-991e-30e2dd5153eb',
      type: ActivityType.running,
      startedAt: now.subtract(const Duration(seconds: 1)),
      resumedAt: now.subtract(const Duration(seconds: 1)),
    );

    Position fix(int seconds, double longitude) => Position(
          latitude: 42,
          longitude: longitude,
          timestamp: now.add(Duration(seconds: seconds)),
          accuracy: 20,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 3,
          speedAccuracy: 0,
        );

    expect(session.recordPosition(fix(0, 23)), isTrue);
    expect(session.recordPosition(fix(5, 23.00018)), isTrue);
    expect(session.distanceMeters, 0);
    expect(session.recordPosition(fix(10, 23.00036)), isTrue);
    expect(session.distanceMeters, greaterThan(25));
    expect(session.gpsCoveredSeconds, 10);
    expect(session.gpsSamples, 3);
  });
}
