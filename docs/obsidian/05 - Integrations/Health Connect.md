---
tags: [lifelevel, integrations]
aliases: [Health Connect, Google Fit, Apple Health]
---
# Health Connect

> Pull-based activity sync from Android's Health Connect (and iOS HealthKit). Reads workouts, distance, calories, steps, heart rate.

## Package

`health: ^11.0.0` — Flutter plugin that wraps Health Connect on Android and HealthKit on iOS.

## Android permissions

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.health.READ_EXERCISE" />
<uses-permission android:name="android.permission.health.READ_EXERCISE_SESSION" />
<uses-permission android:name="android.permission.health.READ_DISTANCE" />
<uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

<queries>
  <package android:name="com.google.android.apps.healthdata" />
</queries>

<activity-alias
    android:name="ViewPermissionUsageActivity"
    android:exported="true"
    android:targetActivity=".MainActivity"
    android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
  <intent-filter>
    <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
    <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
  </intent-filter>
</activity-alias>
```

`minSdk = 26` (Health Connect requires API 26+).

## iOS permissions

`ios/Runner/Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Life Level reads your workouts to award XP and track your fitness progress in the game.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Life Level may write workout summaries to Apple Health.</string>
```

## Sync flow

`HealthSyncService.syncRecentWorkouts()`:

1. Read `lastSyncTime` from `SharedPreferences` key `health_last_sync_ms`.
2. Query `Health()` plugin for workouts in `[lastSyncTime, now]`.
3. For each workout:
   - Map Health Connect `HealthDataType` → our `ActivityType` (see [[Activity Type Mapping]]).
   - Build `ExternalActivityDto(provider="HealthConnect", externalId, activityType, duration, distance, calories, heartRateAvg, performedAt)`.
4. `POST /api/integrations/sync-batch` with batch.
5. Backend dedups + logs each via `IActivityLogPort`.
6. Return `SyncResult(imported, skipped, errors[])`.
7. Update `lastSyncTime` to now.

## Sync triggers

1. **Foreground resume** — `MainShell.didChangeAppLifecycleState(resumed)` calls `_triggerForegroundHealthSync()` if > 15 min since last sync.
2. **Manual "Sync Now" button** — on `IntegrationsScreen`.
3. **App startup** — after login.

## MIUI fallback

> [!warning] Xiaomi's MIUI often blocks the Health Connect permission dialog silently.
> `HealthSyncService.requestPermissions()` detects this and falls back to launching the Health Connect app directly so the user can grant permissions manually. See [[Known Issues]].

## Related
- [[Integrations]] (backend)
- [[Feature - Integrations]] (mobile)
- [[Activity Type Mapping]]
- [[Known Issues]]
- [[Environment Setup]]
