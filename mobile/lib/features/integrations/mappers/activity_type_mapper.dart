import 'package:health/health.dart';

abstract class ActivityTypes {
  static const running  = 'Running';
  static const cycling  = 'Cycling';
  static const swimming = 'Swimming';
  static const hiking   = 'Hiking';
  static const climbing = 'Climbing';
  static const yoga     = 'Yoga';
  static const gym      = 'Gym';
}

abstract class IntegrationProviders {
  static const healthKit     = 'HealthKit';
  static const healthConnect = 'HealthConnect';
  static const strava        = 'Strava';
  static const garmin        = 'Garmin';
}

class ActivityTypeMapper {
  static String fromHealthConnect(HealthWorkoutActivityType type) {
    return switch (type) {
      HealthWorkoutActivityType.RUNNING              => ActivityTypes.running,
      HealthWorkoutActivityType.RUNNING_TREADMILL    => ActivityTypes.running,
      HealthWorkoutActivityType.WALKING              => ActivityTypes.hiking,
      HealthWorkoutActivityType.BIKING               => ActivityTypes.cycling,
      HealthWorkoutActivityType.SWIMMING             => ActivityTypes.swimming,
      HealthWorkoutActivityType.HIKING               => ActivityTypes.hiking,
      HealthWorkoutActivityType.CLIMBING             => ActivityTypes.climbing,
      HealthWorkoutActivityType.ROCK_CLIMBING        => ActivityTypes.climbing,
      HealthWorkoutActivityType.YOGA                 => ActivityTypes.yoga,
      HealthWorkoutActivityType.PILATES              => ActivityTypes.yoga,
      HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING => ActivityTypes.gym,
      HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING  => ActivityTypes.gym,
      HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING => ActivityTypes.gym,
      HealthWorkoutActivityType.CROSS_TRAINING       => ActivityTypes.gym,
      HealthWorkoutActivityType.ELLIPTICAL           => ActivityTypes.gym,
      HealthWorkoutActivityType.ROWING               => ActivityTypes.swimming,
      HealthWorkoutActivityType.ROWING_MACHINE       => ActivityTypes.gym,
      HealthWorkoutActivityType.SURFING              => ActivityTypes.swimming,
      _                                              => ActivityTypes.gym,
    };
  }
}
