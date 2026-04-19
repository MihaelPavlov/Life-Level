---
tags: [lifelevel, dev]
aliases: [Issues, Bugs, Troubleshooting]
---
# Known Issues

> Live gotchas — things that will bite you if you don't know about them.

## ADB troubleshooting

| Symptom | Fix |
|---------|-----|
| `adb devices` returns empty (Xiaomi) | Xiaomi USB driver not installed — install MiFlash Tool from the official Xiaomi site |
| `adb devices` shows `unauthorized` | Unplug, re-plug, re-accept the "Allow USB debugging" dialog on the phone |
| `flutter run` shows no devices | ADB not on PATH, or device not detected — check `adb devices` first |

## ngrok issues

| Symptom | Fix |
|---------|-----|
| `ERR_NGROK_3200` | Session expired — restart ngrok, update `api_client.dart` `_baseUrl`, re-register Strava webhook |
| Flutter `SocketException` | `_baseUrl` in `api_client.dart` not updated with current ngrok URL |
| Strava webhook events not arriving | Old subscription still points at dead ngrok URL — see [[Strava Webhook Registration]] |

## MIUI (Xiaomi) Health Connect

> [!warning] MIUI often blocks the Health Connect permission dialog silently.

`HealthSyncService.requestPermissions()` detects this and falls back to launching the Health Connect app directly. User must grant permissions manually in the Health Connect app itself.

**Workaround for device testing:** Grant permissions manually in Health Connect, then return to Life-Level.

## Garmin PKCE crypto TODO

> [!warning] `GarminService.generateCodeChallenge` currently returns **plain text** because the `crypto` package is not in `pubspec.yaml`. Garmin may reject plain challenges.

**Fix:** add `crypto: ^3.0.3` to pubspec, update `generateCodeChallenge` to use `sha256` hashing.

## OAuth deep-link cold launch

> [!info] **FIXED** as of 2026-04-02 commit `ded8af1`.

Previously: opening Strava OAuth from a cold-start app would fire the deep-link twice, causing duplicate `connect(code)` calls and a unique-index crash on reconnect.

**Fix:** `AndroidManifest.xml` — `launchMode="singleTop"` + `taskAffinity=""` on MainActivity.

## appsettings.json has secrets

> [!warning] `backend/src/LifeLevel.Api/appsettings.json` contains `Strava:ClientSecret` and `Strava:VerifyToken` in plain text. **Dev-only** — must be gitignored / not committed to any public repo. Production must use Azure Key Vault or equivalent.

## Event handler delivery not guaranteed

> [!warning] See [[Cross-Module Events]] — if `ActivityLoggedEvent` handler throws after the commit, streak/quest progress is silently lost. Acceptable at MVP; fix via outbox pattern when an incident occurs.

## Inventory tokens dedup

External activity dedup relies on `ExternalId = "provider:nativeId"`. If two connected providers emit the same workout (e.g., Garmin also pushes to Strava), **both** will be ingested with different external IDs — one workout, two Activity rows. Future improvement: content-based dedup (duration + start time ± tolerance).

## iOS testing — multiple prerequisites pending

> [!info] Not yet configured: HealthKit capability, APNs auth key, Push Notifications capability, `GoogleService-Info.plist`. All require macOS + Xcode + an Apple Developer Program membership. See [[iOS Pre-Testing Setup]] for the full one-sitting checklist.

## `go_router` pulled but unused

`go_router` is in `pubspec.yaml` but not used anywhere — the shell handles all navigation. Safe to remove on next cleanup pass.

## Related
- [[Environment Setup]]
- [[Every-Session Startup]]
- [[Strava Webhook Registration]]
- [[Health Connect]]
- [[Garmin]]
- [[Cross-Module Events]]
- [[iOS Pre-Testing Setup]]
