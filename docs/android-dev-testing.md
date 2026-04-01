# Android Dev Testing Guide

How to run the Life-Level Flutter app on a physical Android device (Redmi Note 8 Pro) for local development.

---

## Prerequisites (one-time setup)

- Flutter SDK installed and on PATH — run `flutter doctor` to verify
- `adb` available — ships with Android Studio / Android SDK platform-tools
- ngrok installed and authenticated:
  ```bash
  ngrok config add-authtoken <your-token>
  ```
- **Xiaomi USB driver installed on Windows** — required for ADB to detect Redmi/MIUI devices.
  Without it, `adb devices` returns empty even with USB debugging on.
  Download: MiFlash Tool or Xiaomi USB Driver from the official Xiaomi developer site.
- USB debugging enabled on device:
  1. Settings → About phone → tap **MIUI version** 7 times to unlock Developer Options
  2. Developer Options → **USB Debugging** → ON

---

## Every-session startup sequence

### Step 1 — Start the backend
 
```bash
cd backend/src/LifeLevel.Api
dotnet run --launch-profile http
```

The API runs on port **5128**.
`appsettings.json` forces HTTP/1.1 (`Kestrel.EndpointDefaults.Protocols = Http1`) — ngrok free tier can't handle HTTP/2.

---

### Step 2 — Start ngrok tunnel

```bash
ngrok http 5128
```

Copy the `https://XXXX.ngrok-free.app` URL from the output.

---

### Step 3 — Update the API base URL in Flutter

Edit `mobile/lib/core/api/api_client.dart`:

```dart
static const _baseUrl = 'https://XXXX.ngrok-free.app/api';
```

> **Important:** Do NOT commit this change. Revert to the placeholder before any `git commit`.

---

### Step 4 — Re-register the Strava webhook

The webhook subscription is bound to the ngrok URL, which changes every session.

**Delete the old subscription** (ID 337974):
```bash
curl -X DELETE "https://www.strava.com/api/v3/push_subscriptions/337974?client_id=218444&client_secret=43b945da369ecd4364c0586eb12f691632f0f1cb"
```

**Register a new subscription** with the current ngrok URL:
```bash
curl -X POST https://www.strava.com/api/v3/push_subscriptions \
  -F client_id=218444 \
  -F client_secret=43b945da369ecd4364c0586eb12f691632f0f1cb \
  -F callback_url=https://XXXX.ngrok-free.app/api/integrations/strava/webhook \
  -F verify_token=lifelevel-webhook-2026
```

The response JSON includes the new subscription ID — update the DELETE command above if it differs from 337974.

---

### Step 5 — Connect the device

Plug the Redmi into the PC via USB, then accept the **"Allow USB debugging"** dialog that appears on the phone.

---

### Step 6 — Verify ADB detects the device

```bash
adb devices
```

Expected output: a serial number with status `device`.
If you see `unauthorized` or nothing, see Troubleshooting below.

---

### Step 7 — Run the app

```bash
cd mobile
flutter run
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `adb devices` returns empty | Xiaomi USB driver not installed — install MiFlash Tool from the official Xiaomi site |
| `adb devices` shows `unauthorized` | Unplug, re-plug, and re-accept the dialog on the phone |
| ngrok `ERR_NGROK_3200` | Session expired — restart ngrok and repeat steps 2–4 |
| Flutter `SocketException` / can't reach API | `_baseUrl` in `api_client.dart` not updated with the current ngrok URL |
| Strava webhook events not arriving | Old subscription still active — repeat step 4 |
| `flutter run` shows no devices | ADB not on PATH, or device not detected — check step 6 first |

---

## Notes

- The ngrok URL change in `api_client.dart` **must be reverted before committing**.
- iOS testing requires one additional manual step: open `ios/Runner.xcworkspace` in Xcode → Signing & Capabilities → add the **HealthKit** capability (not yet done).
- Strava credentials (client ID 218444, client secret) live in `appsettings.json` — dev environment only, do not commit to a public repo.
