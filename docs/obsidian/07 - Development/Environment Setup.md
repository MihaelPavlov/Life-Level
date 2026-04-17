---
tags: [lifelevel, dev]
aliases: [Dev Environment, Setup, Prerequisites]
---
# Environment Setup

> Everything you need installed once before running the project locally.

## Prerequisites

- **Flutter SDK** — `flutter doctor` must pass
- **.NET 8 SDK** — for the backend API
- **PostgreSQL connection string** — points to Supabase-hosted Postgres (in `appsettings.json`)
- **ADB** — ships with Android Studio / Android SDK platform-tools
- **ngrok** — for exposing the local backend to Strava webhooks and physical Android devices
  ```bash
  ngrok config add-authtoken <your-token>
  ```
- **Xiaomi USB driver** (Windows only) — required for ADB to detect Redmi/MIUI devices. Without it, `adb devices` returns empty even with USB debugging on.
  - Download: MiFlash Tool or Xiaomi USB Driver from the official Xiaomi developer site.
- **USB debugging on the phone:**
  1. Settings → About phone → tap **MIUI version** 7 times to unlock Developer Options
  2. Developer Options → **USB Debugging** → ON

## Backend port

The API runs on **HTTP port 5128**.

`appsettings.json` forces **HTTP/1.1** (`Kestrel.EndpointDefaults.Protocols = Http1`) because ngrok free tier can't handle HTTP/2.

## Strava credentials

Live in `backend/src/LifeLevel.Api/appsettings.json`:
- `Strava:ClientId` = 218444
- `Strava:ClientSecret` = (secret — do not commit to public repo)
- `Strava:VerifyToken` = `lifelevel-webhook-2026`

> [!warning] Dev environment only. Production must use Azure Key Vault / secret manager.

## API base URL in Flutter

`mobile/lib/core/api/api_client.dart` has:

```dart
static const _baseUrl = 'http://10.0.2.2:5128/api';
```

- **Android emulator** — leave as-is (`10.0.2.2` maps to host `localhost`).
- **Physical Android device** — swap to the current ngrok HTTPS URL (see [[Every-Session Startup]]).
- **iOS Simulator** — use `http://localhost:5128/api`.

> [!warning] The ngrok URL change in `api_client.dart` **must be reverted before committing**.

## iOS extra step (not yet done)

Open `ios/Runner.xcworkspace` in Xcode → Signing & Capabilities → add **HealthKit** capability. Required for HealthKit integration on real devices.

## Related
- [[Every-Session Startup]]
- [[Strava Webhook Registration]]
- [[Known Issues]]
- [[Architecture Overview]]
