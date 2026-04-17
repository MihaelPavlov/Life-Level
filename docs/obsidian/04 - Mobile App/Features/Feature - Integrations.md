---
tags: [lifelevel, mobile, integrations]
aliases: [Integrations Feature, Health Connect Client, Strava Client]
---
# Feature — Integrations

> Unified screen for connecting Health Connect, Strava, and Garmin. Handles OAuth deep-link callbacks and foreground health sync.

## Files

```
lib/features/integrations/
├── screens/
│   └── integrations_screen.dart
├── models/
│   └── integration_models.dart
├── services/
│   ├── health_sync_service.dart
│   ├── strava_service.dart
│   └── garmin_service.dart
└── providers/
    └── integrations_provider.dart
```

## IntegrationsScreen

Tiles for each integration:
- **Health Connect** — permission status, "Sync Now", last sync time
- **Strava** — connection status (athlete name), Connect / Disconnect
- **Garmin** — same pattern as Strava
- Sync result banner — "Imported 5, skipped 2"

## HealthSyncService

```dart
Future<bool> isPermissionGranted();
Future<bool> requestPermissions();   // opens Health Connect settings; MIUI fallback
Future<DateTime?> getLastSyncTime();  // SharedPreferences 'health_last_sync_ms'
Future<SyncResult> syncRecentWorkouts();  // reads since lastSync, POSTs batch
```

Uses the `health` package. Reads:
- `READ_EXERCISE`
- `READ_DISTANCE`
- `READ_TOTAL_CALORIES_BURNED`
- `READ_STEPS`
- `READ_HEART_RATE`

On MIUI (Xiaomi), the permission dialog often fails to appear — fallback launches the Health Connect app directly. See [[Known Issues]].

## StravaService

```dart
String get authorizationUrl;      // with client_id, scope, redirect_uri=lifelevel://oauth/strava
Future<StravaStatusDto> getStatus();
Future<StravaStatusDto> connect(String code);   // exchanges code server-side
Future<void> disconnect();
```

OAuth flow: open `authorizationUrl` via `url_launcher` → Strava redirects to `lifelevel://oauth/strava?code=...` → `MainShell._handleDeepLink` catches it → `StravaService.connect(code)` → backend exchanges, stores tokens, grants Strava Sync Badge.

## GarminService

```dart
static String generateCodeVerifier();          // cryptographic random string
static String generateCodeChallenge(String verifier);  // SHA-256; currently fallback is plain (TODO)
String authorizationUrl(String codeChallenge);
Future<GarminStatusDto> getStatus();
Future<GarminStatusDto> connect(String code, String codeVerifier);
Future<void> disconnect();
```

> [!warning] Code challenge SHA-256 requires the `crypto` package (not yet in pubspec). Current fallback is plain-text which Garmin may reject. See [[Known Issues]].

## IntegrationSyncState

```dart
class IntegrationSyncState {
  bool isHealthConnected, isSyncing;
  bool isStravaConnected, isGarminConnected;
  DateTime? lastSyncAt;
  String? stravaAthleteName, garminDisplayName;
  SyncResult? lastResult;
}
```

## IntegrationSyncNotifier

```dart
class IntegrationSyncNotifier extends Notifier<IntegrationSyncState> {
  Future<void> requestPermissions();
  Future<void> syncNow();
  Future<String?> connectStrava(String code);
  Future<String?> connectGarmin(String code, String codeVerifier);
  Future<void> disconnectStrava();
  Future<void> disconnectGarmin();
}
```

## Foreground auto-sync

`MainShell.didChangeAppLifecycleState(AppLifecycleState.resumed)` calls `_triggerForegroundHealthSync` — fetches workouts since last sync if >15 min elapsed.

## Related
- [[Strava]]
- [[Health Connect]]
- [[Garmin]]
- [[Integrations]] (backend)
- [[Activity Type Mapping]]
- [[Routing and Deep Links]]
- [[Known Issues]]
