---
tags: [lifelevel, dev]
aliases: [Dev Session Checklist, Startup Checklist]
---
# Every-Session Startup

> The 7-step checklist to run Life-Level on a physical Android device. From `docs/android-dev-testing.md`.

## Step 1 — Start the backend

```bash
cd backend/src/LifeLevel.Api
dotnet run --launch-profile http
```

Runs on **port 5128**. Leave this terminal open.

## Step 2 — Start ngrok tunnel

```bash
ngrok http 5128
```

Copy the `https://XXXX.ngrok-free.app` URL from the output.

## Step 3 — Update API base URL in Flutter

Do not edit `mobile/lib/core/api/api_client.dart`. Pass the current tunnel URL at launch:

```powershell
flutter run -d <device-serial> --dart-define=API_BASE_URL=https://XXXX.ngrok-free.app/api
```

> [!warning] Use the runtime override so temporary tunnel URLs stay out of source control.

## Step 4 — Re-register the Strava webhook

The webhook subscription is bound to the ngrok URL, which changes every session. See [[Strava Webhook Registration]] for the full commands.

## Step 5 — Connect the device

Plug the Redmi into the PC via USB, then accept the **"Allow USB debugging"** dialog that appears on the phone.

## Step 6 — Verify ADB detects the device

```bash
adb devices
```

Expected output: a serial number with status `device`. If `unauthorized` or empty, see [[Known Issues]].

## Step 7 — Run the app

```bash
cd mobile
flutter run -d <device-serial> --dart-define=API_BASE_URL=https://XXXX.ngrok-free.app/api
```

## Related
- [[Environment Setup]]
- [[Strava Webhook Registration]]
- [[Known Issues]]
