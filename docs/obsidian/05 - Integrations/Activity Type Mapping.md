---
tags: [lifelevel, integrations, reference]
aliases: [Type Mapping, Sport Type Mapping]
---
# Activity Type Mapping

> External platforms use their own activity type enums. This note is the single source of truth for how they map to our 8 internal `ActivityType` values.

## Our internal enum

```csharp
enum ActivityType {
  Running, Cycling, Gym, Yoga, Swimming, Hiking, Walking, Climbing
}
```

## Strava `sport_type` → ActivityType

| Strava sport_type | Our type |
|-------------------|----------|
| `Run`, `TrailRun`, `VirtualRun` | Running |
| `Ride`, `VirtualRide`, `MountainBikeRide`, `GravelRide`, `EBikeRide` | Cycling |
| `Swim` | Swimming |
| `Hike` | Hiking |
| `Walk` | Walking |
| `RockClimbing` | Climbing |
| `Yoga` | Yoga |
| `WeightTraining`, `Workout`, `Crossfit`, `Elliptical`, `StairStepper`, `Rowing` | Gym |
| anything else | skip (not imported) |

## Health Connect `ExerciseType` → ActivityType

(Values from the `health` plugin)

| Health Connect type | Our type |
|---------------------|----------|
| `RUNNING`, `RUNNING_TREADMILL` | Running |
| `BIKING`, `BIKING_STATIONARY` | Cycling |
| `SWIMMING_POOL`, `SWIMMING_OPEN_WATER` | Swimming |
| `HIKING` | Hiking |
| `WALKING` | Walking |
| `ROCK_CLIMBING`, `CLIMBING` | Climbing |
| `YOGA`, `PILATES`, `STRETCHING` | Yoga |
| `STRENGTH_TRAINING`, `WEIGHTLIFTING`, `CALISTHENICS`, `HIIT`, `CIRCUIT_TRAINING`, `OTHER_WORKOUT` | Gym |
| anything else | skip |

## HealthKit `HKWorkoutActivityType` → ActivityType

Same logical mapping as Health Connect. The `health` plugin abstracts both.

## Garmin

Uses a mapping similar to Strava but via its own `activityType` field (`running`, `cycling`, `swimming`, `hiking`, `walking`, `strength_training`, etc.).

## Implementation location

- Backend: `LifeLevel.Modules.Integrations/Application/UseCases/ActivityTypeMapper.cs`
- Mobile: `lib/features/integrations/services/health_sync_service.dart` (local mapping for batch payload)

## Related
- [[Activity System]]
- [[Integrations]]
- [[Strava]]
- [[Health Connect]]
- [[Garmin]]
